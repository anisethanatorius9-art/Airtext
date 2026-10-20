<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GroupCallSession extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'room_name',
        'host_id',
        'status',
        'expires_at',
        'started_at',
        'ended_at',
    ];

    /** @return BelongsTo<User, $this> */
    public function host(): BelongsTo
    {
        return $this->belongsTo(User::class, 'host_id');
    }

    /** @return HasMany<GroupCallParticipant, $this> */
    public function participants(): HasMany
    {
        return $this->hasMany(GroupCallParticipant::class);
    }
}
