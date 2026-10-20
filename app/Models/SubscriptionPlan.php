<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property string $code
 * @property string $name
 * @property int $price_tzs
 * @property int|null $duration_days
 * @property string|null $description
 * @property array<int, string>|null $features
 * @property array<string, mixed>|null $entitlements
 * @property bool $is_active
 * @property int $sort_order
 */
class SubscriptionPlan extends Model
{
    protected $fillable = [
        'code',
        'name',
        'price_tzs',
        'duration_days',
        'description',
        'features',
        'entitlements',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'price_tzs' => 'integer',
            'duration_days' => 'integer',
            'features' => 'array',
            'entitlements' => 'array',
            'is_active' => 'boolean',
        ];
    }

    /** @return HasMany<Subscription, $this> */
    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }
}
