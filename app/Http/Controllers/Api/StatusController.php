<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Status;
use App\Models\User;
use App\Services\PrivacyVisibility;
use App\Services\SubscriptionEntitlements;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class StatusController extends Controller
{
    public function index(Request $request, PrivacyVisibility $visibility): JsonResponse
    {
        $user = $request->user();
        $statuses = Status::query()
            ->where('expires_at', '>', now())
            ->where(fn (Builder $query) => $query
                ->where('privacy', 'Everyone')
                ->orWhere('privacy', 'Contacts')
                ->orWhere('user_id', $user->id))
            ->with('user:id,email,status_visibility,links_visibility')
            ->withCount(['viewers', 'likes'])
            ->latest()
            ->get();
        $viewedIds = DB::table('status_views')
            ->where('user_id', $user->id)
            ->pluck('status_id');
        $likedIds = DB::table('status_likes')
            ->where('user_id', $user->id)
            ->pluck('status_id');

        $statuses = $statuses->reject(function (Status $status) use ($user, $viewedIds, $visibility): bool {
            if ($status->view_once && $viewedIds->contains($status->id)) {
                return true;
            }

            $author = $status->user;

            return $author === null
                || ! $visibility->canView($author, $user, $author->status_visibility)
                || ! $visibility->canView($author, $user, $status->privacy);
        });

        return response()->json([
            'data' => $statuses->map(fn (Status $status): array => $this->serializeStatus(
                $status,
                $user,
                $viewedIds->contains($status->id),
                $likedIds->contains($status->id),
                $visibility,
            )),
        ]);
    }

    public function store(
        Request $request,
        PrivacyVisibility $visibility,
        SubscriptionEntitlements $entitlements,
    ): JsonResponse
    {
        $validated = $request->validate([
            'body' => ['nullable', 'required_without:media', 'string', 'max:700'],
            'media' => ['nullable', 'required_without:body', 'file', 'mimes:jpg,jpeg,png,webp,mp4,mov', 'max:51200'],
            'caption' => ['nullable', 'string', 'max:2000'],
            'background' => ['nullable', 'regex:/^#[0-9a-fA-F]{6}$/'],
            'font' => ['nullable', 'in:sans,serif,mono'],
            'privacy' => ['nullable', 'in:Everyone,Contacts'],
            'view_once' => ['nullable', 'boolean'],
            'screenshot_protected' => ['nullable', 'boolean'],
        ]);
        $user = $request->user();
        if ($request->hasFile('media')) {
            $entitlements->assertStorageAvailable($user, $request->file('media')->getSize());
        }
        $mediaPath = $request->file('media')?->store('statuses', 'public');

        $status = Status::query()->create([
            'user_id' => $user->id,
            'body' => $validated['body'] ?? null,
            'media_path' => $mediaPath,
            'media_type' => $mediaPath === null ? 'text' : 'media',
            'caption' => $validated['caption'] ?? null,
            'privacy' => $validated['privacy'] ?? 'Everyone',
            'view_once' => $request->boolean('view_once', false),
            'screenshot_protected' => $request->boolean('screenshot_protected', false),
            'background' => $validated['background'] ?? '#00a884',
            'font' => $validated['font'] ?? 'sans',
            'author_name' => $user->name,
            'author_initials' => Str::upper(Str::substr($user->name, 0, 2)),
            'expires_at' => now()->addDay(),
        ]);

        $status->load('user:id,email,status_visibility,links_visibility')->loadCount('viewers');

        return response()->json([
            'data' => $this->serializeStatus($status, $user, false, false, $visibility),
        ], 201);
    }

    public function markViewed(
        Request $request,
        Status $status,
        PrivacyVisibility $visibility,
    ): JsonResponse {
        $user = $request->user();
        $status->loadMissing('user');
        $author = $status->user;
        abort_unless(
            $status->expires_at->isFuture()
                && $status->user_id !== $user->id
                && $author !== null
                && $visibility->canView($author, $user, $author->status_visibility)
                && $visibility->canView($author, $user, $status->privacy),
            404,
        );

        DB::table('status_views')->updateOrInsert(
            ['status_id' => $status->id, 'user_id' => $user->id],
            ['viewed_at' => now(), 'created_at' => now(), 'updated_at' => now()],
        );

        return response()->json(['message' => 'Status marked as viewed.']);
    }

    public function viewers(Request $request, Status $status): JsonResponse
    {
        abort_unless($status->user_id === $request->user()->id, 404);

        $viewers = DB::table('status_views')
            ->join('users', 'users.id', '=', 'status_views.user_id')
            ->where('status_views.status_id', $status->id)
            ->orderByDesc('status_views.viewed_at')
            ->get([
                'users.id',
                'users.name',
                'status_views.viewed_at',
            ]);

        return response()->json(['data' => $viewers]);
    }

    public function likers(Request $request, Status $status): JsonResponse
    {
        abort_unless($status->user_id === $request->user()->id, 404);

        $likers = DB::table('status_likes')
            ->join('users', 'users.id', '=', 'status_likes.user_id')
            ->where('status_likes.status_id', $status->id)
            ->orderByDesc('status_likes.created_at')
            ->get([
                'users.id',
                'users.name',
                'status_likes.created_at as liked_at',
            ]);

        return response()->json(['data' => $likers]);
    }

    public function like(
        Request $request,
        Status $status,
        PrivacyVisibility $visibility,
    ): JsonResponse {
        $user = $request->user();
        $author = $status->user;
        abort_unless(
            $status->expires_at->isFuture()
                && $status->user_id !== $user->id
                && $author !== null
                && $visibility->canView($author, $user, $author->status_visibility)
                && $visibility->canView($author, $user, $status->privacy),
            404,
        );

        DB::table('status_likes')->updateOrInsert(
            ['status_id' => $status->id, 'user_id' => $user->id],
            ['created_at' => now(), 'updated_at' => now()],
        );

        return response()->json([
            'liked' => true,
            'likes_count' => DB::table('status_likes')->where('status_id', $status->id)->count(),
        ]);
    }

    public function unlike(Request $request, Status $status): JsonResponse
    {
        DB::table('status_likes')
            ->where('status_id', $status->id)
            ->where('user_id', $request->user()->id)
            ->delete();

        return response()->json([
            'liked' => false,
            'likes_count' => DB::table('status_likes')->where('status_id', $status->id)->count(),
        ]);
    }

    /** @return array<string, mixed> */
    private function serializeStatus(
        Status $status,
        User $user,
        bool $hasViewed,
        bool $hasLiked,
        PrivacyVisibility $visibility,
    ): array {
        return [
            'id' => $status->id,
            'author_name' => $status->author_name,
            'author_initials' => $status->author_initials,
            'author_email' => $status->user !== null
                && $visibility->canView($status->user, $user, $status->user->links_visibility)
                    ? $status->user->email
                    : null,
            'body' => $status->body,
            'caption' => $status->caption,
            'media_url' => $status->media_path === null
                ? null
                : $this->publicStorageUrl($status->media_path),
            'media_type' => $status->media_type,
            'privacy' => $status->privacy,
            'view_once' => (bool) $status->view_once,
            'screenshot_protected' => (bool) $status->screenshot_protected,
            'background' => $status->background,
            'font' => $status->font,
            'created_at' => $status->created_at,
            'expires_at' => $status->expires_at,
            'is_mine' => $status->user_id === $user->id,
            'has_viewed' => $hasViewed,
            'views_count' => $status->viewers_count ?? 0,
            'has_liked' => $hasLiked,
            'likes_count' => $status->likes_count ?? 0,
        ];
    }

    private function publicStorageUrl(string $path): string
    {
        /** @var \Illuminate\Filesystem\FilesystemAdapter $disk */
        $disk = Storage::disk('public');

        return $disk->url($path);
    }
}
