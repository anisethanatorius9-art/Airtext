<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

/**
 * @property int $id
 * @property int $owner_id
 * @property string $name
 * @property string $slug
 * @property string|null $description
 * @property string|null $avatar_path
 * @property bool $is_public
 * @property-read int $members_count
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
class Channel extends Model
{
    protected $fillable = [
        'owner_id',
        'name',
        'slug',
        'description',
        'avatar_path',
        'is_public',
    ];

    protected $casts = [
        'is_public' => 'boolean',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $channel): void {
            $channel->slug = $channel->slug ?: Str::slug($channel->name);
        });
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function members(): HasMany
    {
        return $this->hasMany(ChannelMember::class);
    }

    public function posts(): HasMany
    {
        return $this->hasMany(ChannelPost::class)->latest('published_at');
    }

    public function isMember(User $user): bool
    {
        return $this->members()->where('user_id', $user->getKey())->exists();
    }
}
