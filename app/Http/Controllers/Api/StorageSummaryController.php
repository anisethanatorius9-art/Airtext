<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class StorageSummaryController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $conversationIds = Conversation::query()
            ->where(fn ($query) => $query->where('owner_id', $user->id)->orWhere('recipient_id', $user->id))
            ->pluck('id');
        $smsConversationIds = Conversation::query()
            ->where('owner_id', $user->id)
            ->whereNull('recipient_id')
            ->pluck('id');
        $voicePaths = Message::query()
            ->whereIn('conversation_id', $conversationIds)
            ->where('sender_id', $user->id)
            ->whereNotNull('media_path')
            ->pluck('media_path');
        $disk = Storage::disk('local');
        $storageBytes = $voicePaths->unique()->sum(
            fn (string $path): int => $disk->exists($path) ? $disk->size($path) : 0,
        );
        $periodStart = now()->startOfMonth()->toDateString();
        $networkUsage = DB::table('user_network_usage')
            ->where('user_id', $user->id)
            ->where('period_start', $periodStart)
            ->first();

        return response()->json([
            'storage' => [
                'conversation_count' => $conversationIds->count(),
                'message_count' => Message::query()->whereIn('conversation_id', $conversationIds)->count(),
                'voice_count' => $voicePaths->count(),
                'storage_bytes' => $storageBytes,
                'sms_conversation_count' => $smsConversationIds->count(),
                'sms_message_count' => Message::query()->whereIn('conversation_id', $smsConversationIds)->count(),
            ],
            'network_usage' => [
                'uploaded_bytes' => (int) ($networkUsage->uploaded_bytes ?? 0),
                'downloaded_bytes' => (int) ($networkUsage->downloaded_bytes ?? 0),
                'request_count' => (int) ($networkUsage->request_count ?? 0),
                'period_label' => now()->format('F Y'),
            ],
        ]);
    }
}
