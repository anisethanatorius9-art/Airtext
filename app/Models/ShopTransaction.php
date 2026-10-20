<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property int $user_id
 * @property string $reference_id
 * @property string $package_id
 * @property float $amount
 * @property string $currency
 * @property string $payment_gateway
 * @property string $phone_number
 * @property string $status
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 */
class ShopTransaction extends Model
{
    protected $table = 'shop_transactions';

    protected $fillable = [
        'user_id',
        'reference_id',
        'package_id',
        'amount',
        'currency',
        'payment_gateway',
        'phone_number',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'float',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
