<?php

namespace App\Http\Controllers\Api;

use App\Events\CallSignal;
use App\Http\Controllers\Controller;
use App\Models\CallSession;
use App\Models\GroupCallParticipant;
use App\Models\GroupCallSession;
use App\Services\FirebasePushService;
use App\Services\LiveKitTokenService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use LogicException;

class GroupCallController extends Controller
{
    public function active(Request $request): JsonResponse
    {
        $sessions = GroupCallSession::query()
            ->with('host:id,name')
            ->whereIn('status', ['ringing', 'active'])
            ->whereHas('participants', fn ($query) => $query
                ->where('user_id', $request->user()->id)
                ->where('status', 'invited'))
            ->latest()
            ->get();

        return response()->json([
            'data' => $sessions->map(fn (GroupCallSession $session): array => $this->serialize($session)),
        ]);
    }

    public function store(
        Request $request,
        LiveKitTokenService $tokens,
        FirebasePushService $push,
    ): JsonResponse {
        if (! $this->liveKitConfigured()) {
            return $this->liveKitUnavailable();
        }

        $validated = $request->validate([
            'participant_ids' => ['required', 'array', 'min:2', 'max:7'],
            'participant_ids.*' => ['required', 'integer', 'distinct', 'exists:users,id'],
        ]);

        $host = $request->user();
        $participantIds = collect($validated['participant_ids'])->map(fn ($id): int => (int) $id);

        if ($participantIds->contains($host->id)) {
            throw ValidationException::withMessages([
                'participant_ids' => 'The host is added to the room automatically.',
            ]);
        }

        $allParticipantIds = $participantIds->concat([(int) $host->id])->unique()->values();
        $busyUserIds = GroupCallParticipant::query()
            ->whereIn('user_id', $allParticipantIds)
            ->whereIn('status', ['invited', 'joined'])
            ->whereHas('groupCallSession', fn ($query) => $query->whereIn('status', ['ringing', 'active']))
            ->pluck('user_id')
            ->merge(CallSession::query()
                ->whereIn('status', ['ringing', 'accepted'])
                ->where(fn ($query) => $query
                    ->whereIn('caller_id', $allParticipantIds)
                    ->orWhereIn('callee_id', $allParticipantIds))
                ->get(['caller_id', 'callee_id'])
                ->flatMap(fn (CallSession $call): array => [$call->caller_id, $call->callee_id]))
            ->unique();

        if ($busyUserIds->isNotEmpty()) {
            return response()->json(['message' => 'A participant is already in a call.'], 409);
        }

        try {
            $sessionId = (string) Str::uuid();
            $session = DB::transaction(function () use ($host, $participantIds, $sessionId): GroupCallSession {
                $session = GroupCallSession::query()->create([
                    'id' => $sessionId,
                    'room_name' => 'airtext-'.$sessionId,
                    'host_id' => $host->id,
                    'status' => 'ringing',
                    'expires_at' => now()->addSeconds(45),
                ]);

                $session->participants()->create([
                    'user_id' => $host->id,
                    'role' => 'host',
                    'status' => 'joined',
                    'joined_at' => now(),
                ]);

                foreach ($participantIds as $participantId) {
                    $session->participants()->create([
                        'user_id' => $participantId,
                        'role' => 'participant',
                        'status' => 'invited',
                    ]);
                }

                return $session;
            });

            foreach ($participantIds as $participantId) {
                broadcast(new CallSignal(
                    recipientId: $participantId,
                    callId: $session->id,
                    kind: 'group-incoming',
                    senderId: (int) $host->id,
                    payload: [
                        'caller_name' => $host->name,
                        'participants_count' => $participantIds->count() + 1,
                    ],
                ));
                $push->sendCallInvite($participantId, $session->id, $host->name, group: true);
            }

            return response()->json([
                'data' => [
                    ...$this->serialize($session),
                    'server_url' => config('services.livekit.url'),
                    'token' => $tokens->issue($session, $host),
                ],
            ], 201);
        } catch (LogicException $exception) {
            return response()->json(['message' => $exception->getMessage()], 503);
        }
    }

    public function accept(
        Request $request,
        GroupCallSession $groupCallSession,
        LiveKitTokenService $tokens,
    ): JsonResponse {
        if (! $this->liveKitConfigured()) {
            return $this->liveKitUnavailable();
        }

        $participant = $groupCallSession->participants()
            ->where('user_id', $request->user()->id)
            ->firstOrFail();
        abort_unless($participant->status === 'invited', 409);
        abort_unless(in_array($groupCallSession->status, ['ringing', 'active'], true), 409);

        $participant->forceFill(['status' => 'joined', 'joined_at' => now()])->save();
        $groupCallSession->forceFill([
            'status' => 'active',
            'started_at' => $groupCallSession->started_at ?? now(),
            'expires_at' => null,
        ])->save();

        return response()->json([
            'data' => [
                ...$this->serialize($groupCallSession),
                'server_url' => config('services.livekit.url'),
                'token' => $tokens->issue($groupCallSession, $request->user()),
            ],
        ]);
    }

    public function decline(Request $request, GroupCallSession $groupCallSession): JsonResponse
    {
        $participant = $groupCallSession->participants()
            ->where('user_id', $request->user()->id)
            ->firstOrFail();
        abort_unless($participant->status === 'invited', 409);

        $participant->forceFill(['status' => 'declined', 'left_at' => now()])->save();

        broadcast(new CallSignal(
            recipientId: (int) $groupCallSession->host_id,
            callId: $groupCallSession->id,
            kind: 'group-declined',
            senderId: (int) $request->user()->id,
            payload: ['participant_name' => $request->user()->name],
        ));

        return response()->json(['message' => 'Group call declined.']);
    }

    public function token(
        Request $request,
        GroupCallSession $groupCallSession,
        LiveKitTokenService $tokens,
    ): JsonResponse {
        if (! $this->liveKitConfigured()) {
            return $this->liveKitUnavailable();
        }

        $participant = $groupCallSession->participants()
            ->where('user_id', $request->user()->id)
            ->whereIn('status', ['invited', 'joined'])
            ->firstOrFail();
        abort_unless(in_array($groupCallSession->status, ['ringing', 'active'], true), 409);

        $participant->forceFill([
            'status' => 'joined',
            'joined_at' => $participant->joined_at ?? now(),
        ])->save();
        $groupCallSession->forceFill([
            'status' => 'active',
            'started_at' => $groupCallSession->started_at ?? now(),
            'expires_at' => null,
        ])->save();

        return response()->json([
            'data' => [
                ...$this->serialize($groupCallSession),
                'server_url' => config('services.livekit.url'),
                'token' => $tokens->issue($groupCallSession, $request->user()),
            ],
        ]);
    }

    public function leave(Request $request, GroupCallSession $groupCallSession): JsonResponse
    {
        $participant = $groupCallSession->participants()
            ->where('user_id', $request->user()->id)
            ->whereIn('status', ['invited', 'joined'])
            ->firstOrFail();

        $participant->forceFill(['status' => 'left', 'left_at' => now()])->save();

        if ($participant->role === 'host') {
            $groupCallSession->forceFill(['status' => 'ended', 'ended_at' => now()])->save();
            $groupCallSession->participants()
                ->whereIn('status', ['invited', 'joined'])
                ->update(['status' => 'left', 'left_at' => now()]);

            foreach ($groupCallSession->participants()->where('user_id', '!=', $request->user()->id)->pluck('user_id') as $userId) {
                broadcast(new CallSignal(
                    recipientId: (int) $userId,
                    callId: $groupCallSession->id,
                    kind: 'group-ended',
                    senderId: (int) $request->user()->id,
                ));
            }
        }

        return response()->json(['message' => 'You left the group call.']);
    }

    /** @return array<string, mixed> */
    private function serialize(GroupCallSession $session): array
    {
        return [
            'id' => $session->id,
            'room_name' => $session->room_name,
            'host_id' => $session->host_id,
            'host_name' => $session->host?->name,
            'status' => $session->status,
            'participants_count' => $session->participants()->whereIn('status', ['invited', 'joined'])->count(),
        ];
    }

    private function liveKitConfigured(): bool
    {
        return (string) config('services.livekit.url') !== '' &&
            (string) config('services.livekit.api_key') !== '' &&
            strlen((string) config('services.livekit.api_secret')) >= 32;
    }

    private function liveKitUnavailable(): JsonResponse
    {
        return response()->json(['message' => 'AirText group calling is not configured.'], 503);
    }
}
