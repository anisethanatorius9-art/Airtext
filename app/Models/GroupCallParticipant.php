<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GroupCallParticipant extends Model
{
    protected $fillable = [
        'group_call_session_id',
        'user_id',
        'role',
        'status',
        'joined_at',
        'left_at',
    ];

    /** @return BelongsTo<GroupCallSession, $this> */
    public function groupCallSession(): BelongsTo
    {
        return $this->belongsTo(GroupCallSession::class);
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
