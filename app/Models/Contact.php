<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Contact extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'phone_number', 'status_bio', 'payload_prefix', 'is_registered'];

    protected function casts(): array
    {
        return ['is_registered' => 'boolean'];
    }

    public function conversations(): HasMany
    {
        return $this->hasMany(Conversation::class, 'phone_number', 'phone_number');
    }
}
