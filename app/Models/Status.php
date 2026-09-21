<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Status extends Model
{
    use HasFactory;

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
        return ['expires_at' => 'datetime'];
    }
}
