<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use App\Services\SmsGateway;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use RuntimeException;

class ConversationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $conversations = Conversation::query()
            ->where(fn (Builder $query) => $query
                ->where('owner_id', $user->id)
                ->orWhere('recipient_id', $user->id))
            ->with(['owner:id,name,email', 'recipient:id,name,email'])
            ->withCount(['messages as unread_count' => fn (Builder $query) => $query
                ->whereIn('status', ['sent', 'delivered'])
                ->where(fn (Builder $sender) => $sender
                    ->where('sender_id', '!=', $user->id)
                    ->orWhere(fn (Builder $incomingSms) => $incomingSms
                        ->whereNull('sender_id')
                        ->where('direction', 'inbound')))])
            ->with(['messages' => fn ($query) => $query->latest('sent_at')->limit(100)])
            ->latest('updated_at')
            ->get();

        return response()->json([
            'data' => $conversations->map(fn (Conversation $conversation) => $this->serializeConversation($conversation, $user)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'recipient_email' => ['nullable', 'required_without:phone_number', 'email:rfc', 'max:255'],
            'phone_number' => ['nullable', 'required_without:recipient_email', 'regex:/^\+[1-9]\d{7,14}$/'],
            'name' => ['nullable', 'string', 'max:255'],
        ]);
        $user = $request->user();
        $recipient = null;
        $email = isset($validated['recipient_email']) ? strtolower($validated['recipient_email']) : null;

        if ($email !== null) {
            $recipient = User::query()->where('email', $email)->first();
            if ($recipient === null || $recipient->is($user)) {
                throw ValidationException::withMessages([
                    'recipient_email' => 'That AirText account is unavailable.',
                ]);
            }
        }

        $conversation = Conversation::query()
            ->where(function (Builder $query) use ($user, $recipient, $validated): void {
                if ($recipient !== null) {
                    $query->where(fn (Builder $pair) => $pair
                        ->where('owner_id', $user->id)
                        ->where('recipient_id', $recipient->id))
                        ->orWhere(fn (Builder $pair) => $pair
                            ->where('owner_id', $recipient->id)
                            ->where('recipient_id', $user->id));
                } else {
                    $query->where('owner_id', $user->id)
                        ->where('phone_number', $validated['phone_number']);
                }
            })
            ->first();

        if ($conversation === null) {
            $conversation = Conversation::query()->create([
                'owner_id' => $user->id,
                'recipient_id' => $recipient?->id,
                'recipient_email' => $email,
                'phone_number' => $validated['phone_number'] ?? null,
                'name' => trim($validated['name'] ?? '') ?: ($recipient->name ?? $validated['phone_number']),
            ]);
        }

        $conversation->load(['owner:id,name,email', 'recipient:id,name,email', 'messages']);

        return response()->json([
            'data' => $this->serializeConversation($conversation, $user),
        ], 201);
    }

    public function send(Request $request, Conversation $conversation, SmsGateway $smsGateway): JsonResponse
    {
        $user = $request->user();
        abort_unless(
            $conversation->owner_id === $user->id || $conversation->recipient_id === $user->id,
            404,
        );

        $validated = $request->validate([
            'body' => ['required', 'string', 'max:4000'],
        ]);
        $isSms = $conversation->recipient_id === null;
        $message = null;

        $message = DB::transaction(function () use ($conversation, $user, $validated, $isSms): Message {
            $message = $conversation->messages()->create([
                'sender_id' => $user->id,
                'direction' => $conversation->owner_id === $user->id ? 'outbound' : 'inbound',
                'body' => $validated['body'],
                'payload_prefix' => 'MSG:',
                'status' => $isSms ? 'failed' : 'sent',
                'sent_at' => now(),
            ]);
            $conversation->touch();

            return $message;
        });

        if ($isSms) {
            try {
                $smsGateway->send($conversation->phone_number, $validated['body']);
            } catch (RuntimeException $exception) {
                $message->forceFill(['status' => 'failed'])->save();

                return response()->json([
                    'message' => $exception->getMessage(),
                    'data' => $this->serializeMessage($message, $user),
                ], 503);
            }

            $message->forceFill(['status' => 'sent'])->save();
        }

        return response()->json([
            'data' => $this->serializeMessage($message, $user),
        ], 201);
    }

    public function markRead(Request $request, Conversation $conversation): JsonResponse
    {
        $user = $request->user();
        abort_unless(
            $conversation->owner_id === $user->id || $conversation->recipient_id === $user->id,
            404,
        );

        $conversation->messages()
            ->whereIn('status', ['sent', 'delivered'])
            ->where(fn (Builder $sender) => $sender
                ->where('sender_id', '!=', $user->id)
                ->orWhere(fn (Builder $incomingSms) => $incomingSms
                    ->whereNull('sender_id')
                    ->where('direction', 'inbound')))
            ->update(['status' => 'read', 'updated_at' => now()]);

        return response()->json(['message' => 'Messages marked as read.']);
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeConversation(Conversation $conversation, User $user): array
    {
        $counterpart = $conversation->owner_id === $user->id
            ? $conversation->recipient
            : $conversation->owner;
        $messages = $conversation->messages->sortBy('sent_at')->values();

        return [
            'id' => $conversation->id,
            'name' => $counterpart->name ?? $conversation->name,
            'email' => $counterpart->email ?? null,
            'phone_number' => $conversation->phone_number,
            'route' => $conversation->recipient_id === null ? 'sms' : 'airtext',
            'updated_at' => $conversation->updated_at,
            'unread_count' => $conversation->unread_count ?? 0,
            'messages' => $messages->map(fn (Message $message) => $this->serializeMessage($message, $user)),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeMessage(Message $message, User $user): array
    {
        return [
            'id' => $message->id,
            'body' => $message->body,
            'sent_at' => $message->sent_at,
            'sender_id' => $message->sender_id,
            'is_mine' => $message->sender_id === $user->id,
            'status' => $message->status,
        ];
    }
}
