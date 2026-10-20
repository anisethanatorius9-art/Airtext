<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Laravel\Fortify\Contracts\PasskeyUser;
use Laravel\Fortify\PasskeyAuthenticatable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Sanctum\HasApiTokens;

/**
 * @property int $id
 * @property string $name
 * @property string $email
 * @property string|null $profile_photo_path
 * @property Carbon|null $last_seen_at
 * @property Carbon|null $email_verified_at
 * @property string|null $phone_number
 * @property Carbon|null $phone_verified_at
 * @property string $app_language
 * @property string $last_seen_visibility
 * @property string $profile_picture_visibility
 * @property string $about_visibility
 * @property string $links_visibility
 * @property string $status_visibility
 * @property bool $disappearing_messages
 * @property array<string, mixed>|null $storage_settings
 * @property array<string, mixed>|null $messaging_settings
 * @property string $password
 * @property string|null $two_factor_secret
 * @property string|null $two_factor_recovery_codes
 * @property Carbon|null $two_factor_confirmed_at
 * @property string|null $remember_token
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable([
    'name',
    'email',
    'password',
    'phone_number',
    'phone_verified_at',
    'app_language',
    'last_seen_visibility',
    'profile_picture_visibility',
    'about_visibility',
    'links_visibility',
    'status_visibility',
    'disappearing_messages',
    'storage_settings',
            'messaging_settings',
    'profile_photo_path',
    'last_seen_at',
])]
#[Hidden(['password', 'two_factor_secret', 'two_factor_recovery_codes', 'remember_token'])]
class User extends Authenticatable implements PasskeyUser
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, PasskeyAuthenticatable, TwoFactorAuthenticatable;

    /** @return HasMany<Conversation, $this> */
    public function ownedConversations(): HasMany
    {
        return $this->hasMany(Conversation::class, 'owner_id');
    }

    /** @return HasMany<Conversation, $this> */
    public function receivedConversations(): HasMany
    {
        return $this->hasMany(Conversation::class, 'recipient_id');
    }

    /** @return HasMany<Channel, $this> */
    public function ownedChannels(): HasMany
    {
        return $this->hasMany(Channel::class, 'owner_id');
    }

    /** @return HasMany<ChannelMember, $this> */
    public function channelMemberships(): HasMany
    {
        return $this->hasMany(ChannelMember::class);
    }

    /** @return HasMany<UserInstalledBot, $this> */
    public function installedBots(): HasMany
    {
        return $this->hasMany(UserInstalledBot::class);
    }

    /** @return HasMany<ShopTransaction, $this> */
    public function shopTransactions(): HasMany
    {
        return $this->hasMany(ShopTransaction::class);
    }

    /** @return HasMany<Subscription, $this> */
    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'password' => 'hashed',
            'disappearing_messages' => 'boolean',
            'storage_settings' => 'array',
            'messaging_settings' => 'array',
            'last_seen_at' => 'datetime',
        ];
    }

    /**
     * Get the user's initials
     */
    public function initials(): string
    {
        $initials = Str::initials($this->name, true);

        return Str::length($initials) > 1
            ? Str::substr($initials, 0, 1).Str::substr($initials, -1)
            : $initials;
    }
}
