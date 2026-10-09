<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int|null $owner_id
 * @property int|null $recipient_id
 * @property string|null $recipient_email
 * @property string $name
 * @property string|null $phone_number
 * @property string|null $avatar_path
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
class Conversation extends Model
{
    /** @use HasFactory<Factory<Conversation>> */
    use HasFactory;

    protected $fillable = [
        'name',
        'phone_number',
        'avatar_path',
        'owner_id',
        'recipient_id',
        'recipient_email',
    ];

    /** @return BelongsTo<User, $this> */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /** @return BelongsTo<User, $this> */
    public function recipient(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recipient_id');
    }

    /** @return HasMany<Message, $this> */
    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }
}
