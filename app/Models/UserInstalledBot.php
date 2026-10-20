<?php

namespace App\Models;

use App\Services\SubscriptionEntitlements;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property int $user_id
 * @property string $bot_identifier
 * @property string $status
 * @property \Illuminate\Support\Carbon|null $installed_at
 * @property \Illuminate\Support\Carbon|null $expires_at
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 */
class UserInstalledBot extends Model
{
    protected $table = 'user_installed_bots';

    protected $fillable = [
        'user_id',
        'bot_identifier',
        'status',
        'installed_at',
        'expires_at',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $bot): void {
            $user = User::query()->findOrFail($bot->user_id);
            app(SubscriptionEntitlements::class)->authorizeAiBots($user);
        });
    }

    protected function casts(): array
    {
        return [
            'installed_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
