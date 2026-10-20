<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int|null $user_id
 * @property User|null $user
 * @property string|null $body
 * @property string|null $media_path
 * @property string $media_type
 * @property string|null $caption
 * @property string $privacy
 * @property bool $view_once
 * @property bool $screenshot_protected
 * @property string $background
 * @property string $font
 * @property string $author_name
 * @property string $author_initials
 * @property bool $is_viewed
 * @property Carbon $expires_at
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
class Status extends Model
{
    protected $fillable = [
        'body',
        'user_id',
        'media_path',
        'media_type',
        'caption',
        'privacy',
        'view_once',
        'screenshot_protected',
        'background',
        'font',
        'author_name',
        'author_initials',
        'is_viewed',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'is_viewed' => 'boolean',
            'view_once' => 'boolean',
            'screenshot_protected' => 'boolean',
            'expires_at' => 'datetime',
        ];
    }

    /** @return BelongsToMany<User, $this> */
    public function viewers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'status_views')->withPivot('viewed_at');
    }

    /** @return BelongsToMany<User, $this> */
    public function likes(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'status_likes')->withTimestamps();
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
