<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int $conversation_id
 * @property int|null $sender_id
 * @property string $direction
 * @property string $body
 * @property string $message_type
 * @property string|null $media_path
 * @property string $payload_prefix
 * @property string $status
 * @property bool $view_once
 * @property Carbon|null $delivered_at
 * @property Carbon|null $read_at
 * @property Carbon|null $viewed_at
 * @property Carbon|null $expires_at
 * @property Carbon|null $sent_at
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
class Message extends Model
{
    /** @use HasFactory<Factory<Message>> */
    use HasFactory;

    protected $fillable = [
        'conversation_id',
        'sender_id',
        'direction',
        'body',
        'message_type',
        'media_path',
        'payload_prefix',
        'status',
        'view_once',
        'delivered_at',
        'read_at',
        'viewed_at',
        'expires_at',
        'sent_at',
    ];

    protected function casts(): array
    {
        return [
            'body' => 'encrypted',
            'sent_at' => 'datetime',
            'expires_at' => 'datetime',
            'view_once' => 'boolean',
            'delivered_at' => 'datetime',
            'read_at' => 'datetime',
            'viewed_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<Conversation, $this> */
    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }
}
