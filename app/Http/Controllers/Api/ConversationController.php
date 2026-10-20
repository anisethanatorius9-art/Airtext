<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Contact;
use App\Models\Message;
use App\Models\User;
use App\Services\MessageTranslationService;
use App\Services\FirebasePushService;
use App\Services\PrivacyVisibility;
use App\Services\SmsGateway;
use App\Services\SubscriptionEntitlements;
use Illuminate\Broadcasting\BroadcastException;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use RuntimeException;

class ConversationController extends Controller
{
    public function index(Request $request, PrivacyVisibility $visibility): JsonResponse
    {
        $user = $request->user();
        $conversationIds = Conversation::query()
            ->where(fn (Builder $query) => $query
                ->where('owner_id', $user->id)
                ->orWhere('recipient_id', $user->id))
            ->pluck('id');
        Message::query()
            ->whereIn('conversation_id', $conversationIds)
            ->whereNotNull('sender_id')
            ->where('sender_id', '!=', $user->id)
            ->where('status', 'sent')
            ->update(['status' => 'delivered', 'delivered_at' => now(), 'updated_at' => now()]);

        $conversations = Conversation::query()
            ->where(fn (Builder $query) => $query
                ->where('owner_id', $user->id)
                ->orWhere('recipient_id', $user->id))
            ->with(['owner:id,name,email,links_visibility,last_seen_visibility,last_seen_at,profile_picture_visibility,profile_photo_path', 'recipient:id,name,email,links_visibility,last_seen_visibility,last_seen_at,profile_picture_visibility,profile_photo_path'])
            ->withCount(['messages as unread_count' => fn (Builder $query) => $query
                ->where(fn (Builder $expiry) => $expiry
                    ->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now()))
                ->whereIn('status', ['sent', 'delivered'])
                ->where(fn (Builder $sender) => $sender
                    ->where('sender_id', '!=', $user->id)
                    ->orWhere(fn (Builder $incomingSms) => $incomingSms
                        ->whereNull('sender_id')
                        ->where('direction', 'inbound')))])
            ->with(['messages' => fn ($query) => $query
                ->where(fn (Builder $expiry) => $expiry
                    ->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now()))
                ->latest('sent_at')
                ->limit(100)])
            ->latest('updated_at')
            ->get();

        return response()->json([
            'data' => $conversations->map(fn (Conversation $conversation) => $this->serializeConversation($conversation, $user, $visibility)),
        ]);
    }

    public function store(Request $request, PrivacyVisibility $visibility): JsonResponse
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

        $conversation->load(['owner:id,name,email,links_visibility', 'recipient:id,name,email,links_visibility', 'messages']);

        return response()->json([
            'data' => $this->serializeConversation($conversation, $user, $visibility),
        ], 201);
    }

    public function send(
        Request $request,
        Conversation $conversation,
        SmsGateway $smsGateway,
        FirebasePushService $push,
        SubscriptionEntitlements $entitlements,
    ): JsonResponse
    {
        $user = $request->user();
        abort_unless(
            $conversation->owner_id === $user->id || $conversation->recipient_id === $user->id,
            404,
        );

        $validated = $request->validate([
            'body' => ['nullable', 'required_without:media', 'string', 'max:4000'],
            'media' => ['nullable', 'required_if:message_type,voice', 'file', 'mimetypes:audio/aac,audio/mp4,audio/mpeg,audio/ogg,audio/wav,audio/webm', 'max:20480'],
            'message_type' => ['nullable', 'in:text,voice'],
            'view_once' => ['nullable', 'boolean'],
        ]);
        $isSms = $conversation->recipient_id === null;
        $payloadPrefix = $isSms
            ? (Contact::query()->where('phone_number', $conversation->phone_number)->value('payload_prefix')
                ?: ($user->messaging_settings['default_payload_prefix'] ?? 'MSG:'))
            : 'MSG:';
        if ($isSms && $request->hasFile('media')) {
            throw ValidationException::withMessages(['media' => 'Voice messages are only available in Air app chats.']);
        }
        if ($request->hasFile('media')) {
            $entitlements->assertStorageAvailable($user, $request->file('media')->getSize());
        }
        $mediaPath = $request->file('media')?->store('voice-messages/'.$user->id, 'local');
        $messageType = $mediaPath === null ? 'text' : 'voice';

        $message = DB::transaction(function () use ($conversation, $user, $validated, $isSms, $mediaPath, $messageType, $payloadPrefix): Message {
            $message = $conversation->messages()->create([
                'sender_id' => $user->id,
                'direction' => $conversation->owner_id === $user->id ? 'outbound' : 'inbound',
                'body' => $validated['body'] ?? ($messageType === 'voice' ? 'Voice message' : null),
                'message_type' => $messageType,
                'media_path' => $mediaPath,
                'view_once' => (bool) ($validated['view_once'] ?? false),
                'payload_prefix' => $payloadPrefix,
                'status' => $isSms ? 'failed' : 'sent',
                'expires_at' => ! $isSms && $user->disappearing_messages
                    ? now()->addDay()
                    : null,
                'sent_at' => now(),
            ]);
            $conversation->touch();

            return $message;
        });

        if ($isSms) {
            try {
                $smsBody = $payloadPrefix === 'MSG:'
                    ? $validated['body']
                    : $payloadPrefix.$validated['body'];
                $smsGateway->send($conversation->phone_number, $smsBody);
            } catch (RuntimeException $exception) {
                $message->forceFill(['status' => 'failed'])->save();

                return response()->json([
                    'message' => $exception->getMessage(),
                    'data' => $this->serializeMessage($message, $user),
                ], 503);
            }

            $message->forceFill(['status' => 'sent'])->save();
        }

        if (! $isSms) {
            $recipientId = $conversation->owner_id === $user->id
                ? $conversation->recipient_id
                : $conversation->owner_id;
            if ($recipientId !== null) {
                $push->sendMessageAlert(
                    $recipientId,
                    $conversation->id,
                    $entitlements->hasPriorityMessaging($user),
                );
            }

            try {
                MessageSent::dispatch(
                    $conversation->id,
                    $message->id,
                    [$conversation->owner_id, $conversation->recipient_id],
                );
            } catch (BroadcastException $exception) {
                report($exception);
            }
        }

        return response()->json([
            'data' => $this->serializeMessage($message, $user),
        ], 201);
    }

    public function recordLocalSms(Request $request, Conversation $conversation): JsonResponse
    {
        $user = $request->user();
        abort_unless($conversation->owner_id === $user->id && $conversation->recipient_id === null, 404);

        $validated = $request->validate([
            'body' => ['required', 'string', 'max:4000'],
            'payload_prefix' => ['required', 'in:MSG:,STAT:,ACK:'],
        ]);

        $message = $conversation->messages()->create([
            'sender_id' => $user->id,
            'direction' => 'outbound',
            'body' => $validated['body'],
            'message_type' => 'text',
            'payload_prefix' => $validated['payload_prefix'],
            'status' => 'sent',
            'sent_at' => now(),
        ]);
        $conversation->touch();

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

        if (($user->messaging_settings['delivery_receipts'] ?? true) === false) {
            return response()->json(['message' => 'Delivery receipts are disabled.']);
        }

        $conversation->messages()
            ->whereIn('status', ['sent', 'delivered'])
            ->where(fn (Builder $sender) => $sender
                ->where('sender_id', '!=', $user->id)
                ->orWhere(fn (Builder $incomingSms) => $incomingSms
                    ->whereNull('sender_id')
                    ->where('direction', 'inbound')))
            ->update(['status' => 'read', 'read_at' => now(), 'updated_at' => now()]);

        return response()->json(['message' => 'Messages marked as read.']);
    }

    public function openViewOnce(
        Request $request,
        Conversation $conversation,
        Message $message,
    ): JsonResponse {
        $user = $request->user();
        abort_unless(
            ($conversation->owner_id === $user->id || $conversation->recipient_id === $user->id)
                && $message->conversation_id === $conversation->id
                && $message->sender_id !== $user->id
                && $message->view_once
                && $message->viewed_at === null,
            404,
        );

        if ($message->message_type === 'voice') {
            return response()->json([
                'message_type' => 'voice',
                'media_url' => "/conversations/{$conversation->id}/messages/{$message->id}/media",
            ]);
        }

        $message->forceFill([
            'status' => 'read',
            'read_at' => now(),
            'viewed_at' => now(),
        ])->save();

        return response()->json([
            'message_type' => 'text',
            'body' => $message->body,
        ]);
    }

    public function voiceMedia(
        Request $request,
        Conversation $conversation,
        Message $message,
    ): \Symfony\Component\HttpFoundation\BinaryFileResponse {
        $user = $request->user();
        /** @var \Illuminate\Filesystem\FilesystemAdapter $disk */
        $disk = Storage::disk('local');
        abort_unless(
            ($conversation->owner_id === $user->id || $conversation->recipient_id === $user->id)
                && $message->conversation_id === $conversation->id
                && $message->message_type === 'voice'
                && $message->media_path !== null
                && $disk->exists($message->media_path)
                && (! $message->view_once
                    || $message->sender_id === $user->id
                    || $message->viewed_at === null),
            404,
        );

        if ($message->view_once && $message->sender_id !== $user->id) {
            $message->forceFill([
                'status' => 'read',
                'read_at' => now(),
                'viewed_at' => now(),
            ])->save();
        }

        return response()->file(
            $disk->path($message->media_path),
            ['Content-Type' => $disk->mimeType($message->media_path) ?? 'audio/wav'],
        );
    }

    public function attachment(
        Request $request,
        Conversation $conversation,
        Message $message,
    ): \Symfony\Component\HttpFoundation\BinaryFileResponse {
        $user = $request->user();
        $path = $message->media_path;
        /** @var \Illuminate\Filesystem\FilesystemAdapter $disk */
        $disk = Storage::disk('local');
        abort_unless(
            $user instanceof User
                && $conversation->owner_id === $user->id
                && $message->conversation_id === $conversation->id
                && $message->sender_id === $user->id
                && in_array($message->message_type, ['image', 'document'], true)
                && $path !== null
                && str_starts_with($path, 'message-attachments/'.$user->id.'/')
                && $disk->exists($path),
            404,
        );

        $mimeType = $disk->mimeType($path) ?? 'application/octet-stream';
        $headers = [
            'Content-Type' => $mimeType,
            'X-Content-Type-Options' => 'nosniff',
        ];

        if ($message->message_type === 'image' && str_starts_with($mimeType, 'image/')) {
            return response()->file($disk->path($path), $headers);
        }

        return response()->download($disk->path($path), 'attachment-'.$message->id, $headers);
    }

    public function typing(Request $request, Conversation $conversation): JsonResponse
    {
        $user = $request->user();
        abort_unless(
            $conversation->owner_id === $user->id || $conversation->recipient_id === $user->id,
            404,
        );
        $validated = $request->validate([
            'is_typing' => ['required', 'boolean'],
            'activity' => ['nullable', 'in:typing,recording'],
        ]);
        if ($validated['is_typing']) {
            DB::table('conversation_typing')->updateOrInsert(
                ['conversation_id' => $conversation->id, 'user_id' => $user->id],
                [
                    'activity' => $validated['activity'] ?? 'typing',
                    'typing_until' => now()->addSeconds(5),
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            );
        } else {
            DB::table('conversation_typing')
                ->where('conversation_id', $conversation->id)
                ->where('user_id', $user->id)
                ->delete();
        }

        return response()->json(['is_typing' => (bool) $validated['is_typing']]);
    }

    public function typingStatus(Request $request, Conversation $conversation): JsonResponse
    {
        $user = $request->user();
        abort_unless(
            $conversation->owner_id === $user->id || $conversation->recipient_id === $user->id,
            404,
        );
        $typingState = DB::table('conversation_typing')
            ->where('conversation_id', $conversation->id)
            ->where('user_id', '!=', $user->id)
            ->where('typing_until', '>', now())
            ->first(['user_id', 'activity']);

        return response()->json([
            'is_typing' => $typingState !== null,
            'activity' => $typingState?->activity,
            'user_id' => $typingState?->user_id,
        ]);
    }

    public function translateMessage(
        Request $request,
        Conversation $conversation,
        int $message,
        MessageTranslationService $translationService,
    ): JsonResponse {
        $user = $request->user();
        abort_unless(
            $conversation->owner_id === $user->id || $conversation->recipient_id === $user->id,
            404,
        );

        $validated = $request->validate([
            'target_language' => ['required_without:target_lang', 'string', 'in:en,sw,fr,es,ar,zh,pt,hi,ru,de,ja,ko,it,tr,vi,ur,fa,pl,uk,nl,el,bn,pa,jv,te,mr,ta,gu,ha,yo,ig,am,zu,xh,so,id,tl,th,hu,cs,sv,da,fi,no,ro,he,bg,sr,hr,sk'],
            'target_lang' => ['required_without:target_language', 'string', 'in:en,sw,fr,es,ar,zh,pt,hi,ru,de,ja,ko,it,tr,vi,ur,fa,pl,uk,nl,el,bn,pa,jv,te,mr,ta,gu,ha,yo,ig,am,zu,xh,so,id,tl,th,hu,cs,sv,da,fi,no,ro,he,bg,sr,hr,sk'],
            'source_lang' => ['nullable', 'string', 'in:auto,en,sw,fr,es,ar,zh,pt,hi,ru,de,ja,ko,it,tr,vi,ur,fa,pl,uk,nl,el,bn,pa,jv,te,mr,ta,gu,ha,yo,ig,am,zu,xh,so,id,tl,th,hu,cs,sv,da,fi,no,ro,he,bg,sr,hr,sk'],
        ]);
        $targetLanguage = $validated['target_lang'] ?? $validated['target_language'];
        $messageModel = $conversation->messages()->findOrFail($message);
        abort_unless($messageModel->expires_at === null || $messageModel->expires_at->isFuture(), 404);

        try {
            $translation = $translationService->translate(
                $messageModel->body,
                $targetLanguage,
                implode(':', [$user->id, $conversation->id, $messageModel->id]),
                $validated['source_lang'] ?? 'auto',
            );
        } catch (RuntimeException $exception) {
            report($exception);

            return response()->json([
                'message' => __('Message translation is temporarily unavailable.'),
            ], 503);
        }

        return response()->json([
            'translation' => $translation,
            'target_language' => $targetLanguage,
            'translated_text' => $translation,
            'target_lang' => $targetLanguage,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeConversation(
        Conversation $conversation,
        User $user,
        PrivacyVisibility $visibility,
    ): array {
        $counterpart = $conversation->owner_id === $user->id
            ? $conversation->recipient
            : $conversation->owner;
        $messages = $conversation->messages->sortBy('sent_at')->values();
        /** @var \Illuminate\Filesystem\FilesystemAdapter $publicDisk */
        $publicDisk = Storage::disk('public');

        return [
            'id' => $conversation->id,
            'name' => $counterpart->name ?? $conversation->name,
            'email' => $counterpart !== null
                && $visibility->canView($counterpart, $user, $counterpart->links_visibility)
                    ? $counterpart->email
                    : null,
            'counterpart_user_id' => $counterpart?->id,
            'profile_photo_url' => $counterpart !== null
                && $counterpart->profile_photo_path !== null
                && $visibility->canView($counterpart, $user, $counterpart->profile_picture_visibility)
                    ? $publicDisk->url($counterpart->profile_photo_path)
                    : null,
            'is_online' => $counterpart?->last_seen_at !== null
                && $counterpart->last_seen_at->gt(now()->subMinutes(2))
                && $visibility->canView($counterpart, $user, $counterpart->last_seen_visibility),
            'last_seen_at' => $counterpart !== null
                && $visibility->canView($counterpart, $user, $counterpart->last_seen_visibility)
                    ? $counterpart->last_seen_at
                    : null,
            'phone_number' => $conversation->phone_number,
            'route' => $conversation->recipient_id === null ? 'sms' : 'airtext',
            'payload_prefix' => $conversation->recipient_id === null
                ? (Contact::query()->where('phone_number', $conversation->phone_number)->value('payload_prefix')
                    ?: ($user->messaging_settings['default_payload_prefix'] ?? 'MSG:'))
                : 'MSG:',
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
        $isRecipient = $message->sender_id !== $user->id;
        $isConsumedViewOnce = $message->view_once && $isRecipient && $message->viewed_at !== null;
        $isPendingViewOnce = $message->view_once && $isRecipient && $message->viewed_at === null;

        return [
            'id' => $message->id,
            'body' => ($isConsumedViewOnce || $isPendingViewOnce) ? null : $message->body,
            'message_type' => $message->message_type,
            'media_url' => $message->media_path !== null && ! $isConsumedViewOnce && ! $isPendingViewOnce
                ? "/conversations/{$message->conversation_id}/messages/{$message->id}/media"
                : null,
            'view_once' => (bool) $message->view_once,
            'view_once_pending' => $isPendingViewOnce,
            'viewed_at' => $message->sender_id === $user->id ? $message->viewed_at : null,
            'sent_at' => $message->sent_at,
            'sender_id' => $message->sender_id,
            'is_mine' => $message->sender_id === $user->id,
            'status' => $message->status,
            'delivered_at' => $message->delivered_at,
            'read_at' => $message->read_at,
            'expires_at' => $message->expires_at,
        ];
    }
}
