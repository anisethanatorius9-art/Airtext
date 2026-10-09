<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property string|null $body
 * @property string|null $media_path
 * @property string $media_type
 * @property string|null $caption
 * @property string $privacy
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
        'media_path',
        'media_type',
        'caption',
        'privacy',
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
            'expires_at' => 'datetime',
        ];
    }
}
