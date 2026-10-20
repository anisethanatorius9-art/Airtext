<?php

namespace App\Services;

use App\Models\ChannelPost;
use App\Models\Message;
use App\Models\Status;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class SubscriptionEntitlements
{
    /** @return array{ai_bots: bool, storage_bytes: int|null, priority_messaging: bool} */
    public function forUser(User $user): array
    {
        $subscription = Subscription::query()
            ->with('plan')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->where('activated_at', '<=', now())
            ->where(fn ($query) => $query->whereNull('ends_at')->orWhere('ends_at', '>', now()))
            ->latest('activated_at')
            ->first();

        $entitlements = $subscription?->plan?->entitlements;
        if ($entitlements === null) {
            $entitlements = SubscriptionPlan::query()
                ->where('code', 'free_starter')
                ->first()?->entitlements;
        }

        $storageBytes = array_key_exists('storage_bytes', $entitlements ?? [])
            ? $entitlements['storage_bytes']
            : 536870912;

        return [
            'ai_bots' => (bool) ($entitlements['ai_bots'] ?? false),
            'storage_bytes' => $storageBytes === null ? null : (int) $storageBytes,
            'priority_messaging' => (bool) ($entitlements['priority_messaging'] ?? false),
        ];
    }

    public function authorizeAiBots(User $user): void
    {
        if (! $this->forUser($user)['ai_bots']) {
            throw new AuthorizationException('An active plan with AI bot access is required.');
        }
    }

    public function hasPriorityMessaging(User $user): bool
    {
        return $this->forUser($user)['priority_messaging'];
    }

    public function assertStorageAvailable(User $user, int $incomingBytes): void
    {
        $limit = $this->forUser($user)['storage_bytes'];
        if ($limit === null) {
            return;
        }

        $paths = Status::query()
            ->where('user_id', $user->id)
            ->whereNotNull('media_path')
            ->pluck('media_path')
            ->merge(ChannelPost::query()
                ->where('author_id', $user->id)
                ->whereNotNull('media_path')
                ->pluck('media_path'));

        $usedBytes = $paths->unique()->sum(function (string $path): int {
            $disk = Storage::disk('public');

            return $disk->exists($path) ? $disk->size($path) : 0;
        });
        $privateMediaPaths = Message::query()
            ->where('sender_id', $user->id)
            ->whereNotNull('media_path')
            ->pluck('media_path')
            ->unique();
        $usedBytes += $privateMediaPaths->sum(function (string $path): int {
            $disk = Storage::disk('local');

            return $disk->exists($path) ? $disk->size($path) : 0;
        });

        if ($usedBytes + $incomingBytes > $limit) {
            throw ValidationException::withMessages([
                'media' => 'This upload would exceed your plan storage limit.',
            ]);
        }
    }
}
