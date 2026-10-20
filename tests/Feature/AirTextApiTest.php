<?php

use App\Events\CallSignal;
use App\Events\MessageSent;
use App\Mail\AirTextLoginCode;
use App\Models\Contact;
use App\Models\CallSession;
use App\Models\Conversation;
use App\Models\DevicePushToken;
use App\Models\GroupCallSession;
use App\Models\Message;
use App\Models\Status;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Models\User;
use App\Models\UserInstalledBot;
use App\Services\FirebasePushService;
use App\Services\PrivacyVisibility;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Client\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

beforeEach(function () {
    Event::fake([MessageSent::class]);
});

test('email OTP creates a verified account with a phone-verification-only token', function () {
    Mail::fake();

    $request = $this->postJson('/api/auth/otp/request', [
        'email' => 'new.user@example.com',
    ]);

    $request->assertAccepted()
        ->assertJsonMissingPath('code');

    $code = null;
    Mail::assertSent(AirTextLoginCode::class, function (AirTextLoginCode $mail) use (&$code): bool {
        $code = $mail->code;

        return $mail->hasTo('new.user@example.com');
    });

    $response = $this->postJson('/api/auth/otp/verify', [
        'email' => 'new.user@example.com',
        'code' => $code,
        'name' => 'New User',
    ]);

    $response->assertOk()
        ->assertJsonPath('user.email', 'new.user@example.com')
        ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);

    $this->withToken($response->json('token'))
        ->getJson('/api/me')
        ->assertForbidden();

    $this->withToken($response->json('token'))
        ->putJson('/api/me/profile', ['name' => 'New User'])
        ->assertOk()
        ->assertJsonPath('user.name', 'New User');
});

test('repeated registration for an existing email reuses the account', function () {
    Mail::fake();
    $user = User::factory()->create([
        'email' => 'returning.user@example.com',
        'name' => 'Returning User',
    ]);

    $this->postJson('/api/auth/otp/request', ['email' => $user->email])
        ->assertAccepted();

    $code = null;
    Mail::assertSent(AirTextLoginCode::class, function (AirTextLoginCode $mail) use (&$code): bool {
        $code = $mail->code;

        return $mail->hasTo('returning.user@example.com');
    });

    $this->postJson('/api/auth/otp/verify', [
        'email' => $user->email,
        'code' => $code,
        'name' => 'A Different Name',
    ])->assertOk()
        ->assertJsonPath('user.id', $user->id);

    expect(User::query()->where('email', $user->email)->count())->toBe(1)
        ->and($user->refresh()->name)->toBe('Returning User');
});

test('mobile access tokens remain valid past seven days unless an expiry is configured', function () {
    config()->set('sanctum.expiration', null);
    $user = User::factory()->create();
    $token = $user->createToken('long-lived-mobile', ['app'])->plainTextToken;

    $this->travel(8)->days();

    $this->withToken($token)
        ->getJson('/api/me')
        ->assertOk()
        ->assertJsonPath('id', $user->id);
});

test('logging out revokes the session but keeps the account and its data', function () {
    $user = User::factory()->create();
    $conversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'name' => 'Saved conversation',
    ]);
    $token = $user->createToken('mobile-session', ['app'])->plainTextToken;

    $this->withToken($token)
        ->deleteJson('/api/auth/token')
        ->assertOk();

    expect(User::query()->find($user->id))->not->toBeNull()
        ->and(Conversation::query()->find($conversation->id))->not->toBeNull();

    Auth::forgetGuards();
    $this->withToken($token)
        ->getJson('/api/me')
        ->assertUnauthorized();
});

test('email OTP rejects incorrect and expired codes', function () {
    Mail::fake();

    $this->postJson('/api/auth/otp/request', ['email' => 'expired@example.com'])
        ->assertAccepted();

    $this->postJson('/api/auth/otp/verify', [
        'email' => 'expired@example.com',
        'code' => '000000',
    ])->assertUnprocessable();
});

test('API honors Swahili locale for validation and email OTP', function () {
    Mail::fake();

    $this->postJson('/api/auth/otp/request', [], ['Accept-Language' => 'sw'])
        ->assertUnprocessable()
        ->assertJsonPath('errors.email.0', 'Sehemu ya barua pepe inahitajika.');

    $this->postJson('/api/auth/otp/request', ['email' => 'swahili@example.com'], [
        'Accept-Language' => 'sw',
    ])->assertAccepted();

    Mail::assertSent(AirTextLoginCode::class, fn (AirTextLoginCode $mail): bool => str_contains($mail->render(), 'Msimbo wako wa uthibitishaji wa AirText ni:')
    );
});

test('API negotiates a regional French language and localizes OTP responses', function () {
    Mail::fake();

    $this->postJson('/api/auth/otp/request', ['email' => 'fr@example.com'], [
        'Accept-Language' => 'fr-FR,fr;q=0.9,en;q=0.8',
    ])->assertAccepted()
        ->assertJsonPath(
            'message',
            'Si cette adresse peut recevoir des codes AirText, un code a été envoyé.',
        );

    Mail::assertSent(AirTextLoginCode::class, fn (AirTextLoginCode $mail): bool => str_contains(
        $mail->render(),
        'Votre code de vérification AirText est :',
    ));
});

test('API translates French validation errors using Accept-Language', function () {
    $this->postJson('/api/auth/otp/request', ['email' => 'invalid'], [
        'Accept-Language' => 'fr-FR',
    ])->assertUnprocessable()
        ->assertJsonPath(
            'errors.email.0',
            'Le champ adresse e-mail doit être une adresse e-mail valide.',
        );
});

test('phone numbers are only bound after a valid SMS code is verified', function () {
    config()->set('services.twilio.sid', 'test-account');
    config()->set('services.twilio.token', 'test-token');
    config()->set('services.twilio.from', '+15005550006');
    Http::fake(['api.twilio.com/*' => Http::response(['sid' => 'message-id'], 201)]);
    $user = User::factory()->create();
    $token = $user->createToken('test', ['phone-verification'])->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/auth/phone/otp/request', ['phone_number' => '+255712345678'], [
            'Accept-Language' => 'sw',
        ])
        ->assertAccepted();

    Http::assertSent(fn ($request): bool => $request['To'] === '+255712345678'
        && str_contains($request['Body'], 'Msimbo wako wa uthibitishaji'));

    $this->withToken($token)
        ->postJson('/api/auth/phone/otp/verify', [
            'phone_number' => '+255712345678',
            'code' => '000000',
        ])->assertUnprocessable();
    expect($user->fresh()->phone_verified_at)->toBeNull();

    $code = null;
    Http::fake(['api.twilio.com/*' => function ($request) use (&$code) {
        preg_match('/code is (\\d{6})/', $request['Body'], $matches);
        $code = $matches[1] ?? null;

        return Http::response(['sid' => 'message-id'], 201);
    }]);

    $this->withToken($token)
        ->postJson('/api/auth/phone/otp/request', ['phone_number' => '+255712345678'])
        ->assertAccepted();
    $verified = $this->withToken($token)
        ->postJson('/api/auth/phone/otp/verify', [
            'phone_number' => '+255712345678',
            'code' => $code,
        ])->assertOk()
        ->assertJsonStructure(['token']);

    expect($user->fresh()->phone_verified_at)->not->toBeNull();
    $fullToken = $verified->json('token');
    $fullTokenId = (int) Str::before($fullToken, '|');
    expect(json_decode(
        DB::table('personal_access_tokens')->where('id', $fullTokenId)->value('abilities'),
        true,
    ))->toBe(['app', 'phone-verification']);

    Auth::forgetGuards();
    $this->withToken($fullToken)
        ->getJson('/api/me')
        ->assertOk()
        ->assertJsonPath('phone_number', '+255712345678');
});

test('sign-in with a verified phone requires the second SMS code before issuing a token', function () {
    config()->set('services.twilio.sid', 'test-account');
    config()->set('services.twilio.token', 'test-token');
    config()->set('services.twilio.from', '+15005550006');
    $code = null;
    Http::fake(['api.twilio.com/*' => function ($request) use (&$code) {
        preg_match('/code is (\\d{6})/', $request['Body'], $matches);
        $code = $matches[1] ?? null;

        return Http::response(['sid' => 'message-id'], 201);
    }]);
    Mail::fake();
    $user = User::factory()->create([
        'phone_number' => '+255712345678',
        'phone_verified_at' => now(),
    ]);

    $this->postJson('/api/auth/otp/request', ['email' => $user->email])->assertAccepted();
    $emailCode = null;
    Mail::assertSent(AirTextLoginCode::class, function (AirTextLoginCode $mail) use (&$emailCode): bool {
        $emailCode = $mail->code;

        return true;
    });

    $challenge = $this->postJson('/api/auth/otp/verify', [
        'email' => $user->email,
        'code' => $emailCode,
    ])->assertOk()
        ->assertJsonPath('requires_phone_verification', true)
        ->assertJsonMissingPath('token')
        ->json('challenge');

    expect($code)->not->toBeNull();

    $this->postJson('/api/auth/phone/otp/verify-login', [
        'challenge' => $challenge,
        'code' => '000000',
    ])->assertUnprocessable();

    $this->postJson('/api/auth/phone/otp/verify-login', [
        'challenge' => $challenge,
        'code' => $code,
    ])->assertOk()
        ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);

    expect(User::query()->where('email', $user->email)->count())->toBe(1);
});

test('authenticated users can update their profile name', function () {
    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->putJson('/api/me/profile', ['name' => 'Aniseth Anatorius'])
        ->assertOk()
        ->assertJsonPath('user.name', 'Aniseth Anatorius');
});

test('deleting an account removes its data and uploaded media but preserves other accounts', function () {
    Storage::fake('public');
    Storage::fake('local');
    $user = User::factory()->create();
    $recipient = User::factory()->create();
    $otherUser = User::factory()->create();
    $conversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'recipient_id' => $recipient->id,
        'name' => $recipient->name,
    ]);
    Message::query()->create([
        'conversation_id' => $conversation->id,
        'sender_id' => $user->id,
        'direction' => 'outbound',
        'body' => 'Private message',
    ]);
    Message::query()->create([
        'conversation_id' => $conversation->id,
        'sender_id' => $recipient->id,
        'direction' => 'inbound',
        'body' => 'Voice message',
        'message_type' => 'voice',
        'media_path' => 'voice-messages/'.$recipient->id.'/reply.wav',
    ]);
    Storage::disk('local')->put('voice-messages/'.$recipient->id.'/reply.wav', 'private audio');
    $status = Status::query()->create([
        'user_id' => $user->id,
        'body' => null,
        'media_path' => 'statuses/private.jpg',
        'media_type' => 'media',
        'privacy' => 'Everyone',
        'author_name' => $user->name,
        'author_initials' => $user->initials(),
        'expires_at' => now()->addDay(),
    ]);
    Storage::disk('public')->put('statuses/private.jpg', 'private media');

    $otherConversation = Conversation::query()->create([
        'owner_id' => $otherUser->id,
        'recipient_id' => $recipient->id,
        'name' => $recipient->name,
    ]);
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->deleteJson('/api/me')
        ->assertOk();

    expect(User::query()->find($user->id))->toBeNull()
        ->and(Conversation::query()->find($conversation->id))->toBeNull()
        ->and(Message::query()->where('conversation_id', $conversation->id)->exists())->toBeFalse()
        ->and(Status::query()->find($status->id))->toBeNull()
        ->and(Conversation::query()->find($otherConversation->id))->not->toBeNull()
        ->and(User::query()->find($recipient->id))->not->toBeNull();
    expect(Storage::disk('public')->exists('statuses/private.jpg'))->toBeFalse();
    expect(Storage::disk('local')->exists('voice-messages/'.$recipient->id.'/reply.wav'))->toBeFalse();
});

test('authenticated users can persist app language and privacy settings', function () {
    $user = User::factory()->create([
        'app_language' => 'English',
        'last_seen_visibility' => 'Everyone',
        'profile_picture_visibility' => 'My contacts',
        'about_visibility' => 'My contacts',
        'links_visibility' => 'My contacts',
        'status_visibility' => 'Everyone',
    ]);
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->putJson('/api/me/preferences', [
            'app_language' => 'Kiswahili (Tanzania)',
            'last_seen_visibility' => 'My contacts',
            'profile_picture_visibility' => 'Nobody',
            'about_visibility' => 'Everyone',
            'links_visibility' => 'Nobody',
            'status_visibility' => 'My contacts',
            'disappearing_messages' => true,
            'storage_settings' => [
                'use_less_data_for_calls' => true,
                'upload_quality' => 'standard',
                'auto_download_quality' => 'high',
                'mobile_data_downloads' => 'none',
                'wifi_downloads' => 'all',
                'roaming_downloads' => 'photos',
                'auto_download_photos' => false,
                'auto_download_videos' => true,
                'auto_download_stickers' => true,
                'auto_download_voice' => false,
            ],
            'messaging_settings' => [
                'default_payload_prefix' => 'STAT:',
                'delivery_receipts' => false,
                'sms_fallback_enabled' => false,
            ],
        ])
        ->assertOk()
        ->assertJsonPath('preferences.app_language', 'Kiswahili (Tanzania)')
        ->assertJsonPath('preferences.last_seen_visibility', 'My contacts')
        ->assertJsonPath('preferences.profile_picture_visibility', 'Nobody')
        ->assertJsonPath('preferences.about_visibility', 'Everyone')
        ->assertJsonPath('preferences.links_visibility', 'Nobody')
        ->assertJsonPath('preferences.status_visibility', 'My contacts')
        ->assertJsonPath('preferences.disappearing_messages', true)
        ->assertJsonPath('preferences.storage_settings.upload_quality', 'standard')
        ->assertJsonPath('preferences.storage_settings.roaming_downloads', 'photos')
        ->assertJsonPath('preferences.storage_settings.auto_download_photos', false)
        ->assertJsonPath('preferences.messaging_settings.default_payload_prefix', 'STAT:')
        ->assertJsonPath('preferences.messaging_settings.delivery_receipts', false)
        ->assertJsonPath('preferences.messaging_settings.sms_fallback_enabled', false);

    expect($user->fresh()->app_language)->toBe('Kiswahili (Tanzania)')
        ->and($user->fresh()->last_seen_visibility)->toBe('My contacts')
        ->and($user->fresh()->profile_picture_visibility)->toBe('Nobody')
        ->and($user->fresh()->about_visibility)->toBe('Everyone')
        ->and($user->fresh()->links_visibility)->toBe('Nobody')
        ->and($user->fresh()->status_visibility)->toBe('My contacts')
        ->and($user->fresh()->disappearing_messages)->toBeTrue()
        ->and($user->fresh()->storage_settings['upload_quality'])->toBe('standard')
        ->and($user->fresh()->messaging_settings['default_payload_prefix'])->toBe('STAT:');

    $this->withToken($token)
        ->getJson('/api/me')
        ->assertOk()
        ->assertJsonPath('app_language', 'Kiswahili (Tanzania)')
        ->assertJsonPath('last_seen_visibility', 'My contacts')
        ->assertJsonPath('profile_picture_visibility', 'Nobody')
        ->assertJsonPath('about_visibility', 'Everyone')
        ->assertJsonPath('links_visibility', 'Nobody')
        ->assertJsonPath('status_visibility', 'My contacts')
        ->assertJsonPath('disappearing_messages', true);
});

test('empty storage and messaging preferences serialize as JSON objects', function () {
    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;

    $response = $this->withToken($token)->getJson('/api/me/preferences')->assertOk();

    expect($response->getContent())
        ->toContain('"storage_settings":{}')
        ->toContain('"messaging_settings":{}');
});

test('authenticated users can create and list shared SMS contacts', function () {
    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/contacts', [
            'name' => 'Neema Studio',
            'phone_number' => '+255763100445',
            'payload_prefix' => 'ACK:',
        ])
        ->assertCreated()
        ->assertJsonPath('data.name', 'Neema Studio')
        ->assertJsonPath('data.payload_prefix', 'ACK:');

    expect(Contact::query()->where('phone_number', '+255763100445')->value('name'))
        ->toBe('Neema Studio')
        ->and(Contact::query()->where('phone_number', '+255763100445')->value('is_registered'))
        ->toBeFalse();

    $this->withToken($token)
        ->getJson('/api/contacts')
        ->assertOk()
        ->assertJsonFragment([
            'name' => 'Neema Studio',
            'phone_number' => '+255763100445',
            'payload_prefix' => 'ACK:',
        ]);
});

test('authenticated users can verify the configured SMS gateway without sending a message', function () {
    config([
        'services.twilio.sid' => 'AC1234567890',
        'services.twilio.token' => 'secret-token',
        'services.twilio.from' => '+15551234567',
    ]);
    Http::fake([
        'https://api.twilio.com/2010-04-01/Accounts/AC1234567890.json' => Http::response([
            'sid' => 'AC1234567890',
        ]),
    ]);
    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->getJson('/api/me/sms-gateway')
        ->assertOk()
        ->assertJsonPath('provider', 'Twilio')
        ->assertJsonPath('configured', true)
        ->assertJsonMissingPath('token');

    $this->withToken($token)
        ->postJson('/api/me/sms-gateway/test')
        ->assertOk()
        ->assertJsonPath('message', 'Twilio connection verified.');

    Http::assertSentCount(1);
});

test('authenticated api traffic is measured against the user account', function () {
    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;
    $payload = ['app_language' => 'English'];
    $response = $this->withToken($token)->putJson('/api/me/preferences', $payload)->assertOk();
    $usage = DB::table('user_network_usage')
        ->where('user_id', $user->id)
        ->where('period_start', now()->startOfMonth()->toDateString())
        ->first();

    expect($usage)->not->toBeNull()
        ->and($usage->request_count)->toBe(1)
        ->and($usage->uploaded_bytes)->toBe(strlen((string) json_encode($payload)))
        ->and($usage->downloaded_bytes)->toBe(strlen((string) $response->getContent()));
});

test('my contacts privacy uses synced address book matches instead of conversations', function () {
    $owner = User::factory()->create(['phone_verified_at' => now()]);
    $savedContact = User::factory()->create([
        'phone_number' => '+255712345678',
        'phone_verified_at' => now(),
    ]);
    $conversationOnly = User::factory()->create();
    $token = $owner->createToken('test')->plainTextToken;

    Conversation::query()->create([
        'owner_id' => $owner->id,
        'recipient_id' => $conversationOnly->id,
        'recipient_email' => $conversationOnly->email,
        'name' => $conversationOnly->name,
    ]);

    $this->withToken($token)
        ->putJson('/api/me/contacts', [
            'phone_numbers' => ['+255712345678'],
        ])
        ->assertOk()
        ->assertJsonPath('matched_contacts', 1);

    $visibility = app(PrivacyVisibility::class);
    expect($visibility->canView($owner, $savedContact, 'My contacts'))->toBeTrue()
        ->and($visibility->canView($owner, $conversationOnly, 'My contacts'))->toBeFalse();
});

test('local phone verification codes can be retrieved from the log without Twilio', function () {
    app()->detectEnvironment(fn (): string => 'local');
    config()->set('services.twilio.sid', null);
    config()->set('services.twilio.token', null);
    config()->set('services.twilio.from', null);

    $user = User::factory()->create();
    $token = $user->createToken('local-phone-verification', ['phone-verification'])->plainTextToken;
    $code = null;
    Log::shouldReceive('info')
        ->once()
        ->with('AirText local phone verification code.', Mockery::on(function (array $context) use (&$code): bool {
            $code = $context['code'] ?? null;

            return ($context['phone_number'] ?? null) === '+255712345678'
                && is_string($code)
                && preg_match('/^\d{6}$/', $code) === 1;
        }));

    $this->withToken($token)
        ->postJson('/api/auth/phone/otp/request', ['phone_number' => '+255712345678'])
        ->assertAccepted();

    $this->withToken($token)
        ->postJson('/api/auth/phone/otp/verify', [
            'phone_number' => '+255712345678',
            'code' => $code,
        ])
        ->assertOk()
        ->assertJsonPath('phone_number', '+255712345678');
});

test('airtext messages are encrypted at rest and visible to both participants only', function () {
    $sender = User::factory()->create();
    $recipient = User::factory()->create();
    $otherUser = User::factory()->create();
    $senderToken = $sender->createToken('test')->plainTextToken;
    $recipientToken = $recipient->createToken('test')->plainTextToken;
    $otherToken = $otherUser->createToken('test')->plainTextToken;

    $conversation = $this->withToken($senderToken)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');

    $this->withToken($senderToken)
        ->postJson("/api/conversations/{$conversation}/messages", ['body' => 'Private AirText message'])
        ->assertCreated()
        ->assertJsonPath('data.body', 'Private AirText message');

    $storedBody = DB::table('messages')->value('body');
    expect($storedBody)->not->toBe('Private AirText message');

    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->getJson('/api/conversations')
        ->assertOk()
        ->assertJsonPath('data.0.messages.0.body', 'Private AirText message');

    Auth::forgetGuards();
    $this->withToken($otherToken)
        ->getJson('/api/me')
        ->assertOk()
        ->assertJsonPath('id', $otherUser->id);

    Auth::forgetGuards();
    $this->withToken($otherToken)
        ->postJson("/api/conversations/{$conversation}/messages", ['body' => 'Intrusion'])
        ->assertNotFound();
});

test('sending an AirText message broadcasts identifiers to both participants', function () {
    $sender = User::factory()->create();
    $recipient = User::factory()->create();
    $token = $sender->createToken('sender')->plainTextToken;
    Event::fake([MessageSent::class]);

    $conversationId = $this->withToken($token)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');

    $messageId = $this->withToken($token)
        ->postJson("/api/conversations/{$conversationId}/messages", ['body' => 'Real-time hello'])
        ->assertCreated()
        ->json('data.id');

    Event::assertDispatched(MessageSent::class, fn (MessageSent $event): bool => $event->conversationId === $conversationId
        && $event->messageId === $messageId
        && $event->userIds === [$sender->id, $recipient->id]
        && $event->broadcastWith() === [
            'conversation_id' => $conversationId,
            'message_id' => $messageId,
        ]
    );
});

test('device push token registration stores the selected message tone', function () {
    $user = User::factory()->create();
    $token = $user->createToken('device')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/device-tokens', [
            'token' => 'firebase-device-token',
            'platform' => 'android',
            'message_tone' => 'Modern ping',
        ])
        ->assertCreated();

    expect(DevicePushToken::query()->where('token', 'firebase-device-token')->value('message_tone'))
        ->toBe('Modern ping');
});

test('shop checkout is unavailable without payment provider credentials', function () {
    config()->set('services.azampay.base_url', '');
    config()->set('services.azampay.token', '');
    $user = User::factory()->create();
    $token = $user->createToken('shop-test', ['app'])->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/shop/checkout', [
            'package_id' => 'pro_monthly',
            'amount' => 50000,
            'phone_number' => '+255712345678',
            'gateway' => 'azampay',
        ])
        ->assertStatus(503)
        ->assertJsonPath('status', 'unavailable');

    expect(DB::table('shop_transactions')->count())->toBe(0);
});

test('paid subscription checkout uses the database price and waits for payment confirmation', function () {
    config()->set('services.azampay.base_url', 'https://payments.test');
    config()->set('services.azampay.token', 'test-payment-token');
    Http::fake(['payments.test/checkout' => Http::response(['accepted' => true], 202)]);
    $user = User::factory()->create();
    $token = $user->createToken('shop-test', ['app'])->plainTextToken;

    $response = $this->withToken($token)
        ->postJson('/api/shop/checkout', [
            'package_id' => 'pro_monthly',
            'amount' => 1,
            'phone_number' => '+255712345678',
            'gateway' => 'azampay',
        ])
        ->assertAccepted()
        ->assertJsonPath('status', 'pending_payment');

    $transaction = DB::table('shop_transactions')->where('reference_id', $response->json('reference_id'))->first();
    $subscription = DB::table('subscriptions')->where('shop_transaction_id', $transaction->id)->first();
    Http::assertSent(fn (Request $request): bool => $request->url() === 'https://payments.test/checkout'
        && $request['reference_id'] === $transaction->reference_id
        && $request['callback_url'] === url('/api/shop/payment-callback'));

    expect((float) $transaction->amount)->toBe(10000.0)
        ->and($subscription->status)->toBe('pending_payment')
        ->and($subscription->ends_at)->toBeNull();
});

test('Selcom checkout uses its signed API and normalizes its signed callback', function () {
    config()->set('services.selcom.base_url', 'https://selcom.test');
    config()->set('services.selcom.api_key', 'test-api-key');
    config()->set('services.selcom.api_secret', 'test-api-secret');
    config()->set('services.selcom.vendor', 'AIRTEXT01');
    Http::fake([
        'selcom.test/v1/checkout/create-order-minimal' => Http::response([
            'resultcode' => '000',
            'result' => 'SUCCESS',
        ], 200),
        'selcom.test/v1/checkout/wallet-payment' => Http::response([
            'resultcode' => '111',
            'result' => 'PENDING',
        ], 200),
    ]);
    $user = User::factory()->create();
    $token = $user->createToken('selcom-test', ['app'])->plainTextToken;
    $checkout = $this->withToken($token)
        ->postJson('/api/shop/checkout', [
            'package_id' => 'pro_monthly',
            'phone_number' => '0712345678',
            'gateway' => 'selcom',
        ])
        ->assertAccepted();
    $referenceId = $checkout->json('reference_id');

    Http::assertSent(fn (Request $request): bool => str_ends_with($request->url(), '/v1/checkout/create-order-minimal')
        && $request['order_id'] === $referenceId
        && $request['vendor'] === 'AIRTEXT01'
        && $request->hasHeader('Digest-Method', 'HS256'));
    Http::assertSent(fn (Request $request): bool => str_ends_with($request->url(), '/v1/checkout/wallet-payment')
        && $request['order_id'] === $referenceId
        && $request['msisdn'] === '255712345678');

    $payload = [
        'transid' => $referenceId,
        'order_id' => $referenceId,
        'reference' => 'SEL_PROVIDER_REF',
        'result' => 'SUCCESS',
        'resultcode' => '000',
        'payment_status' => 'COMPLETED',
        'amount' => '10000',
        'phone' => '255712345678',
    ];
    $timestamp = now()->format('Y-m-d\TH:i:sP');
    $signedFields = implode(',', array_keys($payload));
    $signingString = 'timestamp='.$timestamp;
    foreach ($payload as $field => $value) {
        $signingString .= '&'.$field.'='.$value;
    }
    $this->postJson('/api/shop/payment-callback', $payload, [
        'Authorization' => 'SELCOM '.base64_encode('test-api-key'),
        'Digest-Method' => 'HS256',
        'Timestamp' => $timestamp,
        'Signed-Fields' => $signedFields,
        'Digest' => base64_encode(hash_hmac('sha256', $signingString, 'test-api-secret', true)),
    ])
        ->assertOk()
        ->assertJsonPath('status', 'active');
});

test('a signed payment callback activates the paid plan for its configured duration', function () {
    config()->set('services.azampay.base_url', 'https://payments.test');
    config()->set('services.azampay.token', 'test-payment-token');
    config()->set('services.shop_webhook_secret', 'test-webhook-secret');
    Http::fake(['payments.test/checkout' => Http::response(['accepted' => true], 202)]);
    $user = User::factory()->create();
    $token = $user->createToken('shop-test', ['app'])->plainTextToken;
    $checkout = $this->withToken($token)
        ->postJson('/api/shop/checkout', [
            'package_id' => 'pro_monthly',
            'phone_number' => '+255712345678',
            'gateway' => 'azampay',
        ])
        ->assertAccepted();
    $referenceId = $checkout->json('reference_id');
    $payload = ['reference_id' => $referenceId, 'status' => 'paid'];
    $body = json_encode($payload, JSON_THROW_ON_ERROR);
    $signature = hash_hmac('sha256', $body, 'test-webhook-secret');

    $this->call('POST', '/api/shop/payment-callback', [], [], [], [
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json',
        'HTTP_X_AIRTEXT_PAYMENT_SIGNATURE' => $signature,
    ], $body)
        ->assertOk()
        ->assertJsonPath('status', 'active');

    $this->call('POST', '/api/shop/payment-callback', [], [], [], [
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json',
        'HTTP_X_AIRTEXT_PAYMENT_SIGNATURE' => $signature,
    ], $body)->assertOk();

    $subscription = DB::table('subscriptions')
        ->where('shop_transaction_id', DB::table('shop_transactions')->where('reference_id', $referenceId)->value('id'))
        ->first();

    expect($subscription->status)->toBe('active')
        ->and((int) Carbon::parse($subscription->activated_at)->diffInDays($subscription->ends_at))->toBe(30);
});

test('a paid renewal starts after the active plan ends', function () {
    config()->set('services.azampay.base_url', 'https://payments.test');
    config()->set('services.azampay.token', 'test-payment-token');
    config()->set('services.shop_webhook_secret', 'test-webhook-secret');
    Http::fake(['payments.test/checkout' => Http::response(['accepted' => true], 202)]);
    $user = User::factory()->create();
    $planId = DB::table('subscription_plans')->where('code', 'pro_monthly')->value('id');
    $currentEndsAt = now()->addDays(3)->startOfSecond();
    DB::table('subscriptions')->insert([
        'user_id' => $user->id,
        'subscription_plan_id' => $planId,
        'status' => 'active',
        'activated_at' => now()->subDays(27),
        'ends_at' => $currentEndsAt,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    $token = $user->createToken('shop-test', ['app'])->plainTextToken;
    $checkout = $this->withToken($token)
        ->postJson('/api/shop/checkout', [
            'package_id' => 'pro_monthly',
            'phone_number' => '+255712345678',
            'gateway' => 'azampay',
        ])
        ->assertAccepted();
    $referenceId = $checkout->json('reference_id');
    $body = json_encode(['reference_id' => $referenceId, 'status' => 'paid'], JSON_THROW_ON_ERROR);

    $this->call('POST', '/api/shop/payment-callback', [], [], [], [
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json',
        'HTTP_X_AIRTEXT_PAYMENT_SIGNATURE' => hash_hmac('sha256', $body, 'test-webhook-secret'),
    ], $body)->assertOk();

    $renewal = DB::table('subscriptions')
        ->where('shop_transaction_id', DB::table('shop_transactions')->where('reference_id', $referenceId)->value('id'))
        ->first();
    expect(Carbon::parse($renewal->activated_at)->equalTo($currentEndsAt))->toBeTrue()
        ->and((int) Carbon::parse($renewal->activated_at)->diffInDays($renewal->ends_at))->toBe(30);
});

test('unsigned payment callbacks cannot activate a subscription', function () {
    config()->set('services.shop_webhook_secret', 'test-webhook-secret');

    $this->postJson('/api/shop/payment-callback', [
        'reference_id' => 'AIR_UNKNOWN',
        'status' => 'paid',
    ])->assertUnauthorized();
});

test('AI bots require an active plan with bot access', function () {
    $user = User::factory()->create();

    expect(fn () => UserInstalledBot::query()->create([
        'user_id' => $user->id,
        'bot_identifier' => 'assistant',
    ]))->toThrow(AuthorizationException::class);

    $plan = SubscriptionPlan::query()->where('code', 'pro_monthly')->firstOrFail();
    Subscription::query()->create([
        'user_id' => $user->id,
        'subscription_plan_id' => $plan->id,
        'status' => 'active',
        'activated_at' => now()->subMinute(),
        'ends_at' => now()->addDays(30),
    ]);

    expect(UserInstalledBot::query()->create([
        'user_id' => $user->id,
        'bot_identifier' => 'assistant',
    ]))->toBeInstanceOf(UserInstalledBot::class);
});

test('media uploads are rejected when they exceed the active plan storage limit', function () {
    Storage::fake('public');
    $plan = SubscriptionPlan::query()->where('code', 'free_starter')->firstOrFail();
    $plan->update(['entitlements' => [
        'ai_bots' => false,
        'storage_bytes' => 1,
        'priority_messaging' => false,
    ]]);
    $user = User::factory()->create();
    $token = $user->createToken('storage-test', ['app'])->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/statuses', [
            'media' => UploadedFile::fake()->image('over-limit.jpg'),
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('media');

    expect(Status::query()->where('user_id', $user->id)->count())->toBe(0);
});

test('priority messaging controls Android and Apple push delivery priority', function () {
    config()->set('services.firebase.project_id', 'airtext-test');
    config()->set('services.firebase.client_email', 'push@example.test');
    config()->set('services.firebase.private_key', 'unused-test-key');
    Http::fake([
        'fcm.googleapis.com/v1/projects/*/messages:send' => Http::response([], 200),
    ]);
    Cache::put('firebase-fcm-access-token', 'fcm-test-token', now()->addMinutes(50));
    $user = User::factory()->create();
    DevicePushToken::query()->create([
        'user_id' => $user->id,
        'token' => 'firebase-test-device-token',
        'platform' => 'android',
    ]);
    $push = app(FirebasePushService::class);

    $push->sendMessageAlert($user->id, 12, false);
    $push->sendMessageAlert($user->id, 13, true);

    Http::assertSent(fn (Request $request): bool => str_contains($request->url(), 'messages:send')
        && $request['message']['data']['conversation_id'] === '12'
        && $request['message']['android']['priority'] === 'normal'
        && $request['message']['apns']['headers']['apns-priority'] === '5');
    Http::assertSent(fn (Request $request): bool => str_contains($request->url(), 'messages:send')
        && $request['message']['data']['conversation_id'] === '13'
        && $request['message']['android']['priority'] === 'high'
        && $request['message']['apns']['headers']['apns-priority'] === '10');
});

test('participants can translate an encrypted conversation message without exposing it to outsiders', function () {
    config()->set('services.translation.url', 'https://translation.test');
    config()->set('services.translation.provider', 'libre');
    config()->set('services.translation.key', '');
    Http::fake(['*' => Http::response(['translatedText' => 'Bonjour'], 200)]);
    $sender = User::factory()->create();
    $recipient = User::factory()->create();
    $otherUser = User::factory()->create();
    $senderToken = $sender->createToken('sender')->plainTextToken;
    $recipientToken = $recipient->createToken('recipient')->plainTextToken;
    $otherToken = $otherUser->createToken('other')->plainTextToken;

    $conversationId = $this->withToken($senderToken)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');
    $messageId = $this->withToken($senderToken)
        ->postJson("/api/conversations/{$conversationId}/messages", ['body' => 'Hello, how are you?'])
        ->assertCreated()
        ->json('data.id');

    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->postJson("/api/conversations/{$conversationId}/messages/{$messageId}/translate", [
            'target_language' => 'fr',
            'source_lang' => 'auto',
        ])
        ->assertOk()
        ->assertJsonPath('translation', 'Bonjour')
        ->assertJsonPath('target_language', 'fr');

    Http::assertSent(fn ($request): bool => $request->method() === 'POST'
        && $request->url() === 'https://translation.test/translate'
        && $request['q'] === 'Hello, how are you?'
        && $request['target'] === 'fr'
        && $request['source'] === 'auto'
        && ! array_key_exists('api_key', $request->data()));

    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->postJson("/api/conversations/{$conversationId}/messages/{$messageId}/translate", [
            'target_lang' => 'fr',
        ])
        ->assertOk()
        ->assertJsonPath('translation', 'Bonjour')
        ->assertJsonPath('translated_text', 'Bonjour')
        ->assertJsonPath('target_lang', 'fr');
    Http::assertSentCount(1);

    Auth::forgetGuards();
    $this->withToken($otherToken)
        ->postJson("/api/conversations/{$conversationId}/messages/{$messageId}/translate", [
            'target_language' => 'fr',
        ])
        ->assertNotFound();
});

test('if the translation service is unavailable, the original message is returned instead of a hard failure', function () {
    config()->set('services.translation.url', 'http://127.0.0.1:5000/translate');
    config()->set('services.translation.provider', 'libre');
    config()->set('services.translation.key', '');
    Http::fake([
        'http://127.0.0.1:5000/*' => Http::response([], 503),
    ]);

    $sender = User::factory()->create();
    $recipient = User::factory()->create();
    $senderToken = $sender->createToken('sender')->plainTextToken;
    $recipientToken = $recipient->createToken('recipient')->plainTextToken;

    $conversationId = $this->withToken($senderToken)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');
    $messageId = $this->withToken($senderToken)
        ->postJson("/api/conversations/{$conversationId}/messages", ['body' => 'Hola amigo'])
        ->assertCreated()
        ->json('data.id');

    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->postJson("/api/conversations/{$conversationId}/messages/{$messageId}/translate", [
            'target_language' => 'en',
            'source_lang' => 'es',
        ])
        ->assertOk()
        ->assertJsonPath('translation', 'Hola amigo')
        ->assertJsonPath('translated_text', 'Hola amigo');
});

test('opening a conversation marks incoming messages as read for the sender', function () {
    $sender = User::factory()->create();
    $recipient = User::factory()->create();
    $senderToken = $sender->createToken('sender')->plainTextToken;
    $recipientToken = $recipient->createToken('recipient')->plainTextToken;

    $conversationId = $this->withToken($senderToken)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');
    $this->withToken($senderToken)
        ->postJson("/api/conversations/{$conversationId}/messages", ['body' => 'Hello'])
        ->assertCreated();

    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->getJson('/api/conversations')
        ->assertOk()
        ->assertJsonPath('data.0.unread_count', 1);

    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->postJson("/api/conversations/{$conversationId}/read")
        ->assertOk();

    Auth::forgetGuards();
    $this->withToken($senderToken)
        ->getJson('/api/conversations')
        ->assertOk()
        ->assertJsonPath('data.0.messages.0.status', 'read');

    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->getJson('/api/conversations')
        ->assertOk()
        ->assertJsonPath('data.0.unread_count', 0);
});

test('AirText users establish calls and exchange protected WebRTC signaling', function () {
    $caller = User::factory()->create();
    $callee = User::factory()->create();
    $otherUser = User::factory()->create();
    $callerToken = $caller->createToken('caller')->plainTextToken;
    $calleeToken = $callee->createToken('callee')->plainTextToken;
    $otherToken = $otherUser->createToken('other')->plainTextToken;
    config()->set('broadcasting.default', 'reverb');
    Event::fake([CallSignal::class]);

    $conversationId = $this->withToken($callerToken)
        ->postJson('/api/conversations', ['recipient_email' => $callee->email])
        ->assertCreated()
        ->json('data.id');

    Auth::forgetGuards();
    $callId = $this->withToken($callerToken)
        ->postJson('/api/calls', ['conversation_id' => $conversationId])
        ->assertCreated()
        ->assertJsonPath('data.status', 'ringing')
        ->json('data.id');

    Event::assertDispatched(CallSignal::class, fn (CallSignal $event): bool => $event->recipientId === $callee->id && $event->kind === 'incoming'
    );

    Auth::forgetGuards();
    $calleeConversationId = $this->withToken($calleeToken)
        ->postJson('/api/conversations', ['recipient_email' => $otherUser->email])
        ->assertCreated()
        ->json('data.id');

    Auth::forgetGuards();
    $this->withToken($calleeToken)
        ->postJson('/api/calls', ['conversation_id' => $calleeConversationId])
        ->assertConflict();

    Auth::forgetGuards();
    $this->withToken($calleeToken)
        ->postJson("/api/calls/{$callId}/accept")
        ->assertOk()
        ->assertJsonPath('data.status', 'accepted');

    Auth::forgetGuards();
    $this->withToken($callerToken)
        ->postJson("/api/calls/{$callId}/signals", [
            'kind' => 'offer',
            'payload' => ['type' => 'offer', 'sdp' => 'test-offer-sdp'],
        ])
        ->assertOk();

    Event::assertDispatched(CallSignal::class, fn (CallSignal $event): bool => $event->recipientId === $callee->id && $event->kind === 'offer'
    );

    Auth::forgetGuards();
    $this->withToken($otherToken)
        ->postJson("/api/calls/{$callId}/signals", [
            'kind' => 'offer',
            'payload' => ['type' => 'offer', 'sdp' => 'intrusion'],
        ])
        ->assertNotFound();

    Auth::forgetGuards();
    $this->withToken($callerToken)
        ->postJson('/api/broadcasting/auth', [
            'socket_id' => '123.456',
            'channel_name' => 'private-users.'.$caller->id,
        ])
        ->assertOk();

    Auth::forgetGuards();
    $this->withToken($callerToken)
        ->postJson('/api/broadcasting/auth', [
            'socket_id' => '123.456',
            'channel_name' => 'private-users.'.$otherUser->id,
        ])
        ->assertForbidden();
});

test('ICE configuration returns short-lived per-user TURN credentials', function () {
    config()->set('services.turn.stun_urls', 'stun:turn.airtext.test:3478');
    config()->set('services.turn.urls', 'turn:turn.airtext.test:3478,turns:turn.airtext.test:5349');
    config()->set('services.turn.shared_secret', 'server-only-turn-secret');
    config()->set('services.turn.credential_ttl', 3600);

    $user = User::factory()->create();
    $token = $user->createToken('turn')->plainTextToken;

    $iceServers = $this->withToken($token)
        ->getJson('/api/calls/ice-servers')
        ->assertOk()
        ->assertJsonPath('data.0.urls.0', 'stun:turn.airtext.test:3478')
        ->assertJsonPath('data.1.urls.1', 'turns:turn.airtext.test:5349')
        ->assertJsonMissing(['server-only-turn-secret'])
        ->json('data');

    [$expiresAt, $userId] = explode(':', $iceServers[1]['username']);
    expect((int) $userId)->toBe($user->id)
        ->and((int) $expiresAt)->toBeGreaterThanOrEqual(now()->timestamp + 3599)
        ->and($iceServers[1]['credential'])->toBe(base64_encode(hash_hmac(
            'sha1',
            $iceServers[1]['username'],
            'server-only-turn-secret',
            true,
        )));
});

test('unanswered calls expire and no longer keep a user busy', function () {
    Event::fake([CallSignal::class]);
    $caller = User::factory()->create();
    $callee = User::factory()->create();
    $token = $caller->createToken('caller')->plainTextToken;
    $conversation = Conversation::query()->create([
        'owner_id' => $caller->id,
        'recipient_id' => $callee->id,
        'name' => $callee->name,
    ]);
    $call = CallSession::query()->create([
        'id' => (string) Str::uuid(),
        'conversation_id' => $conversation->id,
        'caller_id' => $caller->id,
        'callee_id' => $callee->id,
        'status' => 'ringing',
    ]);
    $call->forceFill([
        'created_at' => now()->subMinute(),
        'updated_at' => now()->subMinute(),
    ])->save();

    $this->withToken($token)
        ->postJson('/api/calls', ['conversation_id' => $conversation->id])
        ->assertCreated();

    expect($call->fresh()->status)->toBe('missed');
});

test('group calls create self-hosted rooms and issue tokens only to invited users', function () {
    config()->set('broadcasting.default', 'reverb');
    config()->set('services.livekit.url', 'wss://livekit.airtext.test');
    config()->set('services.livekit.api_key', 'airtext-test-key');
    config()->set('services.livekit.api_secret', 'airtext-test-livekit-api-secret-at-least-32-bytes');
    Event::fake([CallSignal::class]);

    $host = User::factory()->create();
    $invitee = User::factory()->create();
    $otherUser = User::factory()->create();
    $stranger = User::factory()->create();
    $hostToken = $host->createToken('host')->plainTextToken;
    $inviteeToken = $invitee->createToken('invitee')->plainTextToken;
    $otherToken = $otherUser->createToken('other')->plainTextToken;
    $strangerToken = $stranger->createToken('stranger')->plainTextToken;

    $response = $this->withToken($hostToken)
        ->postJson('/api/group-calls', ['participant_ids' => [$invitee->id, $otherUser->id]]);
    $response->assertCreated()->assertJsonPath('data.status', 'ringing')->assertJsonPath('data.participants_count', 3);

    $callId = $response->json('data.id');
    $roomName = $response->json('data.room_name');
    $liveKitSecret = 'airtext-test-livekit-api-secret-at-least-32-bytes';
    $hostClaims = JWT::decode($response->json('data.token'), new Key($liveKitSecret, 'HS256'));

    expect($response->json('data.server_url'))->toBe('wss://livekit.airtext.test')
        ->and($hostClaims->sub)->toBe((string) $host->id)
        ->and($hostClaims->video->room)->toBe($roomName)
        ->and($hostClaims->video->roomJoin)->toBeTrue()
        ->and($hostClaims->video->canPublish)->toBeTrue();

    Event::assertDispatchedTimes(CallSignal::class, 2);

    Auth::forgetGuards();
    $inviteeResponse = $this->withToken($inviteeToken)
        ->postJson("/api/group-calls/{$callId}/accept")
        ->assertOk()
        ->assertJsonPath('data.status', 'active');
    $inviteeClaims = JWT::decode($inviteeResponse->json('data.token'), new Key($liveKitSecret, 'HS256'));
    expect($inviteeClaims->sub)->toBe((string) $invitee->id);

    Auth::forgetGuards();
    $this->withToken($otherToken)
        ->getJson("/api/group-calls/{$callId}/token")
        ->assertOk();

    Auth::forgetGuards();
    $this->withToken($strangerToken)
        ->getJson("/api/group-calls/{$callId}/token")
        ->assertNotFound();

    expect(GroupCallSession::query()->findOrFail($callId)->participants()->count())->toBe(3);
});

test('statuses are shared between users with per-viewer read receipts', function () {
    $author = User::factory()->create(['name' => 'Asha Mushi']);
    $viewer = User::factory()->create();
    $authorToken = $author->createToken('author')->plainTextToken;
    $viewerToken = $viewer->createToken('viewer')->plainTextToken;

    $statusId = $this->withToken($authorToken)
        ->postJson('/api/statuses', ['body' => 'Habari za leo'])
        ->assertCreated()
        ->assertJsonPath('data.author_name', 'Asha Mushi')
        ->assertJsonPath('data.is_mine', true)
        ->json('data.id');

    Auth::forgetGuards();
    $this->withToken($viewerToken)
        ->getJson('/api/statuses')
        ->assertOk()
        ->assertJsonPath('data.0.body', 'Habari za leo')
        ->assertJsonPath('data.0.has_viewed', false);

    Auth::forgetGuards();
    $this->withToken($viewerToken)
        ->postJson("/api/statuses/{$statusId}/view")
        ->assertOk();

    Auth::forgetGuards();
    $this->withToken($viewerToken)
        ->getJson('/api/statuses')
        ->assertOk()
        ->assertJsonPath('data.0.has_viewed', true);

    Auth::forgetGuards();
    $this->withToken($authorToken)
        ->getJson('/api/statuses')
        ->assertOk()
        ->assertJsonPath('data.0.views_count', 1)
        ->assertJsonPath('data.0.has_viewed', false);
});

test('profile photo upload persists the file and exposes its URL', function () {
    Storage::fake('public');
    $user = User::factory()->create();
    $token = $user->createToken('profile-photo-test', ['app'])->plainTextToken;

    $response = $this->withToken($token)->post('/api/me/profile-photo', [
        'photo' => UploadedFile::fake()->image('profile.jpg'),
    ])->assertOk();

    $user->refresh();
    expect($user->profile_photo_path)->not->toBeNull()
        ->and(Storage::disk('public')->exists($user->profile_photo_path))->toBeTrue()
        ->and($response->json('profile_photo_url'))->toContain($user->profile_photo_path);
});

test('chat typing state expires and heartbeat persists last seen', function () {
    $sender = User::factory()->create();
    $recipient = User::factory()->create();
    $senderToken = $sender->createToken('typing-sender', ['app'])->plainTextToken;
    $recipientToken = $recipient->createToken('typing-recipient', ['app'])->plainTextToken;
    $conversationId = $this->withToken($senderToken)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');

    $this->withToken($senderToken)
        ->postJson("/api/conversations/{$conversationId}/typing", [
            'is_typing' => true,
            'activity' => 'recording',
        ])
        ->assertOk();
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->getJson("/api/conversations/{$conversationId}/typing")
        ->assertOk()
        ->assertJsonPath('is_typing', true)
        ->assertJsonPath('activity', 'recording');

    Auth::forgetGuards();
    $this->withToken($senderToken)
        ->postJson('/api/me/presence')
        ->assertOk();
    expect($sender->fresh()->last_seen_at)->not->toBeNull();

    $this->travel(6)->seconds();
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->getJson("/api/conversations/{$conversationId}/typing")
        ->assertOk()
        ->assertJsonPath('is_typing', false);
});

test('chat delivery and read receipts consume view-once messages for the recipient', function () {
    $sender = User::factory()->create();
    $recipient = User::factory()->create();
    $senderToken = $sender->createToken('once-sender', ['app'])->plainTextToken;
    $recipientToken = $recipient->createToken('once-recipient', ['app'])->plainTextToken;
    $conversationId = $this->withToken($senderToken)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');
    $messageId = $this->withToken($senderToken)
        ->postJson("/api/conversations/{$conversationId}/messages", [
            'body' => 'Only once',
            'view_once' => true,
        ])
        ->assertCreated()
        ->json('data.id');

    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->getJson('/api/conversations')
        ->assertOk()
        ->assertJsonPath('data.0.messages.0.status', 'delivered')
        ->assertJsonPath('data.0.messages.0.body', null)
        ->assertJsonPath('data.0.messages.0.view_once_pending', true);
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->postJson("/api/conversations/{$conversationId}/read")
        ->assertOk();
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->postJson("/api/conversations/{$conversationId}/messages/{$messageId}/view-once")
        ->assertOk()
        ->assertJsonPath('body', 'Only once');
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->postJson("/api/conversations/{$conversationId}/messages/{$messageId}/view-once")
        ->assertNotFound();
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->getJson('/api/conversations')
        ->assertOk()
        ->assertJsonPath('data.0.messages.0.body', null)
        ->assertJsonPath('data.0.messages.0.status', 'read');

    expect(DB::table('messages')->where('id', $messageId)->value('viewed_at'))->not->toBeNull();
});

test('voice messages upload as playable media and disappear for recipients after view once', function () {
    Storage::fake('local');
    $sender = User::factory()->create();
    $recipient = User::factory()->create();
    $senderToken = $sender->createToken('voice-sender', ['app'])->plainTextToken;
    $recipientToken = $recipient->createToken('voice-recipient', ['app'])->plainTextToken;
    $conversationId = $this->withToken($senderToken)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');

    $message = $this->withToken($senderToken)
        ->post("/api/conversations/{$conversationId}/messages", [
            'message_type' => 'voice',
            'view_once' => true,
            'media' => UploadedFile::fake()->create('voice.wav', 10, 'audio/wav'),
        ])
        ->assertCreated()
        ->assertJsonPath('data.message_type', 'voice')
        ->assertJsonPath('data.view_once', true)
        ->json('data');

    $mediaPath = DB::table('messages')->where('id', $message['id'])->value('media_path');
    expect($mediaPath)->not->toBeNull()
        ->and(Storage::disk('local')->exists($mediaPath))->toBeTrue()
        ->and($message['media_url'])->not->toBeNull();
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->getJson('/api/conversations')
        ->assertOk()
        ->assertJsonPath('data.0.messages.0.media_url', null)
        ->assertJsonPath('data.0.messages.0.view_once_pending', true);
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->get("/api/conversations/{$conversationId}/messages/{$message['id']}/media")
        ->assertOk();
    Auth::forgetGuards();
    $this->withToken($recipientToken)
        ->get("/api/conversations/{$conversationId}/messages/{$message['id']}/media")
        ->assertNotFound();
});

test('status owners can inspect named viewers and receive unique likes', function () {
    $owner = User::factory()->create();
    $viewer = User::factory()->create();
    $ownerToken = $owner->createToken('status-owner', ['app'])->plainTextToken;
    $viewerToken = $viewer->createToken('status-viewer', ['app'])->plainTextToken;
    $statusId = $this->withToken($ownerToken)
        ->postJson('/api/statuses', ['body' => 'Status with viewers'])
        ->assertCreated()
        ->json('data.id');

    Auth::forgetGuards();
    $this->withToken($viewerToken)
        ->postJson("/api/statuses/{$statusId}/view")
        ->assertOk();
    $this->withToken($viewerToken)
        ->postJson("/api/statuses/{$statusId}/like")
        ->assertOk()
        ->assertJsonPath('liked', true)
        ->assertJsonPath('likes_count', 1);
    $this->withToken($viewerToken)
        ->postJson("/api/statuses/{$statusId}/like")
        ->assertOk()
        ->assertJsonPath('likes_count', 1);

    Auth::forgetGuards();
    $this->withToken($ownerToken)
        ->getJson("/api/statuses/{$statusId}/viewers")
        ->assertOk()
        ->assertJsonPath('data.0.id', $viewer->id)
        ->assertJsonPath('data.0.name', $viewer->name);
    $this->withToken($ownerToken)
        ->getJson("/api/statuses/{$statusId}/likes")
        ->assertOk()
        ->assertJsonPath('data.0.id', $viewer->id)
        ->assertJsonPath('data.0.name', $viewer->name);
    Auth::forgetGuards();
    $this->withToken($viewerToken)
        ->getJson("/api/statuses/{$statusId}/viewers")
        ->assertNotFound();
    $this->withToken($viewerToken)
        ->getJson("/api/statuses/{$statusId}/likes")
        ->assertNotFound();
});

test('status audience and profile link visibility are enforced', function () {
    $author = User::factory()->create([
        'status_visibility' => 'My contacts',
        'links_visibility' => 'Nobody',
    ]);
    $contact = User::factory()->create([
        'phone_number' => '+255712345678',
        'phone_verified_at' => now(),
    ]);
    $stranger = User::factory()->create();
    $authorToken = $author->createToken('author')->plainTextToken;
    $contactToken = $contact->createToken('contact')->plainTextToken;
    $strangerToken = $stranger->createToken('stranger')->plainTextToken;

    $statusId = $this->withToken($authorToken)
        ->postJson('/api/statuses', ['body' => 'Contacts only'])
        ->assertCreated()
        ->json('data.id');

    $this->withToken($authorToken)
        ->putJson('/api/me/contacts', ['phone_numbers' => ['+255712345678']])
        ->assertOk();

    Auth::forgetGuards();
    $this->withToken($contactToken)
        ->getJson('/api/statuses')
        ->assertOk()
        ->assertJsonPath('data.0.id', $statusId)
        ->assertJsonPath('data.0.author_email', null);

    $this->withToken($contactToken)
        ->postJson("/api/statuses/{$statusId}/view")
        ->assertOk();

    Auth::forgetGuards();
    $this->withToken($strangerToken)
        ->getJson('/api/statuses')
        ->assertOk()
        ->assertJsonCount(0, 'data');

    $this->withToken($strangerToken)
        ->postJson("/api/statuses/{$statusId}/view")
        ->assertNotFound();
});

test('disappearing messages receive an expiry and are hidden after it passes', function () {
    $sender = User::factory()->create(['disappearing_messages' => true]);
    $recipient = User::factory()->create();
    $token = $sender->createToken('sender')->plainTextToken;

    $conversationId = $this->withToken($token)
        ->postJson('/api/conversations', ['recipient_email' => $recipient->email])
        ->assertCreated()
        ->json('data.id');
    $messageResponse = $this->withToken($token)
        ->postJson("/api/conversations/{$conversationId}/messages", [
            'body' => 'This message expires',
        ])
        ->assertCreated()
        ->assertJsonPath('data.body', 'This message expires');

    $message = Message::query()->findOrFail($messageResponse->json('data.id'));
    expect($message->expires_at)->not->toBeNull()
        ->and($message->expires_at->isFuture())->toBeTrue();

    $message->forceFill(['expires_at' => now()->subSeconds(1)])->save();

    $this->withToken($token)
        ->getJson('/api/conversations')
        ->assertOk()
        ->assertJsonCount(0, 'data.0.messages');

    $this->withToken($token)
        ->postJson("/api/conversations/{$conversationId}/messages/{$message->id}/translate", [
            'target_language' => 'fr',
        ])
        ->assertNotFound();
});

test('public channels can be created, joined, and updated with posts', function () {
    $owner = User::factory()->create(['name' => 'Owner']);
    $member = User::factory()->create(['name' => 'Member']);
    $ownerToken = $owner->createToken('owner')->plainTextToken;
    $memberToken = $member->createToken('member')->plainTextToken;

    $response = $this->withToken($ownerToken)
        ->postJson('/api/channels', [
            'name' => 'AirText Updates',
            'description' => 'Release notes and status updates.',
        ])
        ->assertCreated()
        ->assertJsonPath('data.name', 'AirText Updates')
        ->assertJsonPath('data.slug', 'airtext-updates');

    $channelId = $response->json('data.id');

    Auth::forgetGuards();
    $this->withToken($memberToken)
        ->getJson('/api/channels')
        ->assertOk()
        ->assertJsonPath('data.0.slug', 'airtext-updates');

    Auth::forgetGuards();
    $this->withToken($memberToken)
        ->postJson("/api/channels/{$channelId}/join")
        ->assertOk()
        ->assertJsonPath('data.members_count', 2);

    Auth::forgetGuards();
    $this->withToken($memberToken)
        ->postJson("/api/channels/{$channelId}/posts", ['body' => 'Launch day is live!'])
        ->assertCreated()
        ->assertJsonPath('data.body', 'Launch day is live!');

    Auth::forgetGuards();
    $this->withToken($ownerToken)
        ->getJson("/api/channels/{$channelId}/posts")
        ->assertOk()
        ->assertJsonPath('data.0.body', 'Launch day is live!');
});

test('view-once statuses disappear after viewing and keep privacy metadata', function () {
    $author = User::factory()->create(['name' => 'Safi']);
    $viewer = User::factory()->create(['name' => 'Mila']);
    $authorToken = $author->createToken('author')->plainTextToken;
    $viewerToken = $viewer->createToken('viewer')->plainTextToken;

    $statusId = $this->withToken($authorToken)
        ->postJson('/api/statuses', [
            'body' => 'This disappears after viewing once',
            'view_once' => true,
            'screenshot_protected' => true,
        ])
        ->assertCreated()
        ->assertJsonPath('data.view_once', true)
        ->assertJsonPath('data.screenshot_protected', true)
        ->json('data.id');

    Auth::forgetGuards();
    $this->withToken($viewerToken)
        ->getJson('/api/statuses')
        ->assertOk()
        ->assertJsonPath('data.0.body', 'This disappears after viewing once');

    Auth::forgetGuards();
    $this->withToken($viewerToken)
        ->postJson("/api/statuses/{$statusId}/view")
        ->assertOk();

    Auth::forgetGuards();
    $this->withToken($viewerToken)
        ->getJson('/api/statuses')
        ->assertOk()
        ->assertJsonCount(0, 'data');
});

test('SMS conversations fail explicitly when a gateway is not configured', function () {
    config()->set('services.twilio.sid', null);
    config()->set('services.twilio.token', null);
    config()->set('services.twilio.from', null);

    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;
    $conversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'name' => 'SMS contact',
        'phone_number' => '+255700000111',
    ]);

    $this->withToken($token)
        ->postJson("/api/conversations/{$conversation->id}/messages", ['body' => 'Do not silently drop this'])
        ->assertStatus(503)
        ->assertJsonPath('message', 'SMS delivery is not configured.');

    expect($conversation->messages()->first()->status)->toBe('failed');
});

test('configured Twilio gateway receives SMS with the saved payload prefix', function () {
    config()->set('services.twilio.sid', 'ACtest');
    config()->set('services.twilio.token', 'test-token');
    config()->set('services.twilio.from', '+15005550006');
    Http::fake(['api.twilio.com/*' => Http::response(['status' => 'queued'], 201)]);

    $user = User::factory()->create([
        'messaging_settings' => ['default_payload_prefix' => 'STAT:'],
    ]);
    $token = $user->createToken('test')->plainTextToken;
    $conversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'name' => 'SMS contact',
        'phone_number' => '+255700000111',
    ]);

    $this->withToken($token)
        ->postJson("/api/conversations/{$conversation->id}/messages", ['body' => 'SMS payload'])
        ->assertCreated()
        ->assertJsonPath('data.status', 'sent');

    Http::assertSent(fn ($request): bool => $request->url() === 'https://api.twilio.com/2010-04-01/Accounts/ACtest/Messages.json'
        && $request['To'] === '+255700000111'
        && $request['Body'] === 'STAT:SMS payload'
    );

    expect($conversation->messages()->first()->payload_prefix)->toBe('STAT:');
});

test('device-sent SMS can be recorded without sending it through Twilio again', function () {
    config()->set('services.twilio.sid', null);
    config()->set('services.twilio.token', null);
    config()->set('services.twilio.from', null);
    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;
    $conversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'name' => 'SMS contact',
        'phone_number' => '+255700000112',
    ]);

    $this->withToken($token)
        ->postJson("/api/conversations/{$conversation->id}/messages/local-sms", [
            'body' => 'SIM sent message',
            'payload_prefix' => 'MSG:',
        ])
        ->assertCreated()
        ->assertJsonPath('data.body', 'SIM sent message')
        ->assertJsonPath('data.status', 'sent');

    Http::assertNothingSent();
    expect($conversation->messages()->first()->direction)->toBe('outbound');
});

test('disabled delivery receipts do not mark incoming messages as read', function () {
    $user = User::factory()->create([
        'messaging_settings' => ['delivery_receipts' => false],
    ]);
    $sender = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;
    $conversation = Conversation::query()->create([
        'owner_id' => $sender->id,
        'recipient_id' => $user->id,
        'name' => $user->name,
    ]);
    $message = $conversation->messages()->create([
        'sender_id' => $sender->id,
        'direction' => 'outbound',
        'body' => 'Incoming message',
        'message_type' => 'text',
        'payload_prefix' => 'MSG:',
        'status' => 'sent',
        'sent_at' => now(),
    ]);

    $this->withToken($token)
        ->postJson("/api/conversations/{$conversation->id}/read")
        ->assertOk()
        ->assertJsonPath('message', 'Delivery receipts are disabled.');

    expect($message->fresh()->status)->toBe('sent');
});

test('storage summary returns account totals and current month network usage', function () {
    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;
    $conversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'name' => 'SMS contact',
        'phone_number' => '+255712884102',
    ]);
    $conversation->messages()->create([
        'sender_id' => $user->id,
        'direction' => 'outbound',
        'body' => 'Stored message',
        'message_type' => 'text',
        'payload_prefix' => 'MSG:',
        'status' => 'sent',
        'sent_at' => now(),
    ]);

    $this->withToken($token)
        ->getJson('/api/me/storage-summary')
        ->assertOk()
        ->assertJsonPath('storage.conversation_count', 1)
        ->assertJsonPath('storage.message_count', 1)
        ->assertJsonPath('storage.sms_conversation_count', 1)
        ->assertJsonPath('storage.sms_message_count', 1)
        ->assertJsonPath('network_usage.period_label', now()->format('F Y'));
});
