<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property string $name
 * @property string $phone_number
 * @property string|null $status_bio
 * @property string $payload_prefix
 * @property bool $is_registered
 */
class Contact extends Model
{
    protected $fillable = ['name', 'phone_number', 'status_bio', 'payload_prefix', 'is_registered'];

    protected function casts(): array
    {
        return ['is_registered' => 'boolean'];
    }

    /** @return HasMany<Conversation, $this> */
    public function conversations(): HasMany
    {
        return $this->hasMany(Conversation::class, 'phone_number', 'phone_number');
    }
}
