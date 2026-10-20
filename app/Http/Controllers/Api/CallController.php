<?php

namespace App\Http\Controllers\Api;

use App\Events\CallSignal;
use App\Http\Controllers\Controller;
use App\Models\CallSession;
use App\Models\Conversation;
use App\Services\FirebasePushService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class CallController extends Controller
{
    public function iceServers(Request $request): JsonResponse
    {
        $iceServers = [];
        $stunUrls = array_values(array_filter(array_map(
            'trim',
            explode(',', (string) config('services.turn.stun_urls')),
        )));

        if ($stunUrls !== []) {
            $iceServers[] = ['urls' => $stunUrls];
        }

        $turnUrls = array_values(array_filter(array_map(
            'trim',
            explode(',', (string) config('services.turn.urls')),
        )));
        $sharedSecret = (string) config('services.turn.shared_secret');

        if ($turnUrls !== [] && $sharedSecret !== '') {
            $expiresAt = now()->addSeconds(max(60, (int) config('services.turn.credential_ttl', 3600)));
            $username = $expiresAt->timestamp.':'.$request->user()->id;

            $iceServers[] = [
                'urls' => $turnUrls,
                'username' => $username,
                'credential' => base64_encode(hash_hmac('sha1', $username, $sharedSecret, true)),
            ];
        }

        return response()->json(['data' => $iceServers]);
    }

    public function active(Request $request): JsonResponse
    {
        $this->expireRingingCalls();
        $user = $request->user();
        $call = CallSession::query()
            ->with('caller:id,name')
            ->where('callee_id', $user->id)
            ->where('status', 'ringing')
            ->latest()
            ->first();

        return response()->json(['data' => $call ? $this->serialize($call) : null]);
    }

    public function show(Request $request, CallSession $callSession): JsonResponse
    {
        abort_unless(
            $callSession->caller_id === $request->user()->id ||
                $callSession->callee_id === $request->user()->id,
            404,
        );

        return response()->json(['data' => $this->serialize($callSession)]);
    }

    public function store(Request $request, FirebasePushService $push): JsonResponse
    {
        $this->expireRingingCalls();
        $validated = $request->validate([
            'conversation_id' => ['required', 'integer', 'exists:conversations,id'],
        ]);
        $user = $request->user();
        $conversation = Conversation::query()
            ->whereKey($validated['conversation_id'])
            ->where(fn ($query) => $query
                ->where('owner_id', $user->id)
                ->orWhere('recipient_id', $user->id))
            ->firstOrFail();

        $calleeId = $conversation->owner_id === $user->id
            ? $conversation->recipient_id
            : $conversation->owner_id;

        if ($calleeId === null || $calleeId === $user->id) {
            throw ValidationException::withMessages([
                'conversation_id' => 'Calls are available only between AirText accounts.',
            ]);
        }

        $isBusy = CallSession::query()
            ->whereIn('status', ['ringing', 'accepted'])
            ->where(fn ($query) => $query
                ->whereIn('caller_id', [$user->id, $calleeId])
                ->orWhereIn('callee_id', [$user->id, $calleeId]))
            ->exists();

        if ($isBusy) {
            return response()->json(['message' => 'A participant is already in a call.'], 409);
        }

        $call = DB::transaction(fn () => CallSession::query()->create([
            'id' => (string) Str::uuid(),
            'conversation_id' => $conversation->id,
            'caller_id' => $user->id,
            'callee_id' => $calleeId,
            'status' => 'ringing',
        ]));

        broadcast(new CallSignal(
            recipientId: (int) $calleeId,
            callId: $call->id,
            kind: 'incoming',
            senderId: (int) $user->id,
            payload: ['caller_name' => $user->name],
        ));
        $push->sendCallInvite((int) $calleeId, $call->id, $user->name);

        return response()->json(['data' => $this->serialize($call)], 201);
    }

    public function accept(Request $request, CallSession $callSession): JsonResponse
    {
        abort_unless($callSession->callee_id === $request->user()->id, 404);
        abort_unless($callSession->status === 'ringing', 409);

        $callSession->forceFill([
            'status' => 'accepted',
            'accepted_at' => now(),
        ])->save();

        broadcast(new CallSignal(
            recipientId: (int) $callSession->caller_id,
            callId: $callSession->id,
            kind: 'accepted',
            senderId: (int) $request->user()->id,
        ));

        return response()->json(['data' => $this->serialize($callSession)]);
    }

    public function decline(Request $request, CallSession $callSession): JsonResponse
    {
        abort_unless($callSession->callee_id === $request->user()->id, 404);
        abort_unless($callSession->status === 'ringing', 409);

        $callSession->forceFill(['status' => 'declined', 'ended_at' => now()])->save();

        broadcast(new CallSignal(
            recipientId: (int) $callSession->caller_id,
            callId: $callSession->id,
            kind: 'declined',
            senderId: (int) $request->user()->id,
        ));

        return response()->json(['message' => 'Call declined.']);
    }

    public function signal(Request $request, CallSession $callSession): JsonResponse
    {
        $validated = $request->validate([
            'kind' => ['required', 'in:offer,answer,ice-candidate'],
            'payload' => ['required', 'array'],
            'payload.sdp' => ['sometimes', 'string', 'max:50000'],
            'payload.type' => ['sometimes', 'string', 'in:offer,answer'],
            'payload.candidate' => ['sometimes', 'string', 'max:4000'],
            'payload.sdpMid' => ['sometimes', 'nullable', 'string', 'max:255'],
            'payload.sdpMLineIndex' => ['sometimes', 'nullable', 'integer'],
        ]);
        $user = $request->user();
        abort_unless(
            $callSession->caller_id === $user->id || $callSession->callee_id === $user->id,
            404,
        );
        abort_unless($callSession->status === 'accepted', 409);

        $recipientId = $callSession->caller_id === $user->id
            ? $callSession->callee_id
            : $callSession->caller_id;

        broadcast(new CallSignal(
            recipientId: (int) $recipientId,
            callId: $callSession->id,
            kind: $validated['kind'],
            senderId: (int) $user->id,
            payload: $validated['payload'],
        ));

        return response()->json(['message' => 'Signal sent.']);
    }

    public function end(Request $request, CallSession $callSession): JsonResponse
    {
        $user = $request->user();
        abort_unless(
            $callSession->caller_id === $user->id || $callSession->callee_id === $user->id,
            404,
        );

        if (in_array($callSession->status, ['ringing', 'accepted'], true)) {
            $callSession->forceFill(['status' => 'ended', 'ended_at' => now()])->save();
            $recipientId = $callSession->caller_id === $user->id
                ? $callSession->callee_id
                : $callSession->caller_id;

            broadcast(new CallSignal(
                recipientId: (int) $recipientId,
                callId: $callSession->id,
                kind: 'ended',
                senderId: (int) $user->id,
            ));
        }

        return response()->json(['message' => 'Call ended.']);
    }

    /** @return array<string, mixed> */
    private function serialize(CallSession $call): array
    {
        return [
            'id' => $call->id,
            'conversation_id' => $call->conversation_id,
            'caller_id' => $call->caller_id,
            'callee_id' => $call->callee_id,
            'status' => $call->status,
            'caller_name' => $call->caller?->name,
        ];
    }

    private function expireRingingCalls(): void
    {
        $expiredCalls = CallSession::query()
            ->where('status', 'ringing')
            ->where('created_at', '<=', now()->subSeconds(45))
            ->get();

        foreach ($expiredCalls as $call) {
            $call->forceFill(['status' => 'missed', 'ended_at' => now()])->save();

            broadcast(new CallSignal(
                recipientId: (int) $call->caller_id,
                callId: $call->id,
                kind: 'missed',
                senderId: (int) $call->callee_id,
            ));
        }
    }
}
