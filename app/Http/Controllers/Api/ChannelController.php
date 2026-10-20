<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Channel;
use App\Models\ChannelMember;
use App\Models\ChannelPost;
use App\Models\User;
use App\Services\SubscriptionEntitlements;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ChannelController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $channels = Channel::query()
            ->withCount('members')
            ->with('owner:id,name')
            ->where(fn ($query) => $query
                ->where('is_public', true)
                ->orWhereExists(fn ($memberQuery) => $memberQuery
                    ->from('channel_members')
                    ->whereColumn('channel_members.channel_id', 'channels.id')
                    ->where('channel_members.user_id', $user->id)))
            ->latest()
            ->get();

        return response()->json([
            'data' => $channels->map(fn (Channel $channel): array => $this->serializeChannel($channel, $user)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'slug' => ['nullable', 'string', 'max:255', 'unique:channels,slug'],
            'is_public' => ['nullable', 'boolean'],
        ]);

        $user = $request->user();
        $slug = trim((string) ($validated['slug'] ?? Str::slug($validated['name'])));
        $slug = $this->uniqueSlug($slug);

        $channel = Channel::query()->create([
            'owner_id' => $user->id,
            'name' => trim((string) $validated['name']),
            'slug' => $slug,
            'description' => $validated['description'] ?? null,
            'is_public' => (bool) ($validated['is_public'] ?? true),
        ]);

        $channel->members()->create([
            'user_id' => $user->id,
            'role' => 'admin',
            'joined_at' => now(),
        ]);

        $channel->loadCount('members')->load('owner:id,name');

        return response()->json([
            'data' => $this->serializeChannel($channel, $user),
        ], 201);
    }

    public function show(Request $request, Channel $channel): JsonResponse
    {
        $user = $request->user();

        abort_unless($channel->is_public || $channel->isMember($user), 404);

        $channel->loadCount('members')->load('owner:id,name');

        return response()->json([
            'data' => $this->serializeChannel($channel, $user),
        ]);
    }

    public function join(Request $request, Channel $channel): JsonResponse
    {
        $user = $request->user();

        abort_unless($channel->is_public || $channel->owner_id === $user->id, 404);

        if ($channel->isMember($user)) {
            $channel->loadCount('members')->load('owner:id,name');

            return response()->json([
                'data' => $this->serializeChannel($channel, $user),
            ]);
        }

        $channel->members()->create([
            'user_id' => $user->id,
            'role' => 'member',
            'joined_at' => now(),
        ]);

        $channel->loadCount('members')->load('owner:id,name');

        return response()->json([
            'data' => $this->serializeChannel($channel, $user),
        ]);
    }

    public function leave(Request $request, Channel $channel): JsonResponse
    {
        $user = $request->user();
        $membership = $channel->members()->where('user_id', $user->id)->first();

        abort_unless($membership !== null, 404);
        abort_if($channel->owner_id === $user->id, 409, 'The owner cannot leave the channel.');

        $membership->delete();

        return response()->json(['message' => 'You left the channel.']);
    }

    public function posts(Request $request, Channel $channel): JsonResponse
    {
        $user = $request->user();

        abort_unless($channel->is_public || $channel->isMember($user), 404);

        $posts = $channel->posts()->with('author:id,name')->get();

        return response()->json([
            'data' => $posts->map(fn (ChannelPost $post): array => $this->serializePost($post)),
        ]);
    }

    public function storePost(
        Request $request,
        Channel $channel,
        SubscriptionEntitlements $entitlements,
    ): JsonResponse
    {
        $user = $request->user();

        abort_unless($channel->is_public || $channel->isMember($user), 404);

        $validated = $request->validate([
            'body' => ['nullable', 'required_without:media', 'string', 'max:4000'],
            'media' => ['nullable', 'required_without:body', 'file', 'mimes:jpg,jpeg,png,webp,mp4,mov', 'max:51200'],
        ]);

        if ($request->hasFile('media')) {
            $entitlements->assertStorageAvailable($user, $request->file('media')->getSize());
        }

        $mediaPath = $request->file('media')?->store('channels', 'public');

        $post = $channel->posts()->create([
            'author_id' => $user->id,
            'body' => $validated['body'] ?? null,
            'media_path' => $mediaPath,
            'published_at' => now(),
        ]);

        $post->load('author:id,name');

        return response()->json([
            'data' => $this->serializePost($post),
        ], 201);
    }

    private function serializeChannel(Channel $channel, User $user): array
    {
        $membership = $channel->members()->where('user_id', $user->id)->first();

        return [
            'id' => $channel->id,
            'name' => $channel->name,
            'slug' => $channel->slug,
            'description' => $channel->description,
            'avatar_url' => $channel->avatar_path ? Storage::disk('public')->url($channel->avatar_path) : null,
            'is_public' => (bool) $channel->is_public,
            'is_member' => $membership !== null,
            'role' => $membership?->role,
            'owner_id' => $channel->owner_id,
            'owner_name' => $channel->owner?->name,
            'members_count' => $channel->members_count ?? $channel->members()->count(),
            'created_at' => $channel->created_at,
        ];
    }

    private function serializePost(ChannelPost $post): array
    {
        return [
            'id' => $post->id,
            'channel_id' => $post->channel_id,
            'author_id' => $post->author_id,
            'author_name' => $post->author?->name,
            'body' => $post->body,
            'media_url' => $post->media_path ? Storage::disk('public')->url($post->media_path) : null,
            'published_at' => $post->published_at,
        ];
    }

    private function uniqueSlug(string $slug): string
    {
        $baseSlug = trim($slug) ?: 'channel';
        $candidate = Str::slug($baseSlug) ?: 'channel';
        $counter = 1;

        while (Channel::query()->where('slug', $candidate)->exists()) {
            $candidate = $counter === 1 ? $candidate.'-'.$counter : preg_replace('/-\d+$/', '', $candidate).'-'.$counter;
            $counter++;
        }

        return $candidate;
    }
}
