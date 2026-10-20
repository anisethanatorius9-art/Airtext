<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property Carbon|null $activated_at
 * @property Carbon|null $ends_at
 */
class Subscription extends Model
{
    protected $fillable = [
        'user_id',
        'subscription_plan_id',
        'shop_transaction_id',
        'status',
        'activated_at',
        'ends_at',
    ];

    protected function casts(): array
    {
        return [
            'activated_at' => 'datetime',
            'ends_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return BelongsTo<SubscriptionPlan, $this> */
    public function plan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }

    /** @return BelongsTo<ShopTransaction, $this> */
    public function shopTransaction(): BelongsTo
    {
        return $this->belongsTo(ShopTransaction::class);
    }
}
