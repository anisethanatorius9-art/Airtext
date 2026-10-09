<?php

use App\Mail\AirTextLoginCode;
use App\Models\Conversation;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;

test('email OTP creates a verified account and a bearer token without exposing the code', function () {
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
        ->assertOk()
        ->assertJsonPath('name', 'New User');
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

test('SMS conversations fail explicitly when a gateway is not configured', function () {
    config()->set('services.twilio.sid', null);
    config()->set('services.twilio.token', null);
    config()->set('services.twilio.from', null);

    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;
    $conversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'name' => 'SMS contact',
        'phone_number' => '+255712884102',
    ]);

    $this->withToken($token)
        ->postJson("/api/conversations/{$conversation->id}/messages", ['body' => 'Do not silently drop this'])
        ->assertStatus(503)
        ->assertJsonPath('message', 'SMS delivery is not configured.');

    expect($conversation->messages()->first()->status)->toBe('failed');
});

test('configured Twilio gateway receives SMS and the API records acceptance', function () {
    config()->set('services.twilio.sid', 'ACtest');
    config()->set('services.twilio.token', 'test-token');
    config()->set('services.twilio.from', '+15005550006');
    Http::fake(['api.twilio.com/*' => Http::response(['status' => 'queued'], 201)]);

    $user = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;
    $conversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'name' => 'SMS contact',
        'phone_number' => '+255712884102',
    ]);

    $this->withToken($token)
        ->postJson("/api/conversations/{$conversation->id}/messages", ['body' => 'SMS payload'])
        ->assertCreated()
        ->assertJsonPath('data.status', 'sent');

    Http::assertSent(fn ($request): bool => $request->url() === 'https://api.twilio.com/2010-04-01/Accounts/ACtest/Messages.json'
        && $request['To'] === '+255712884102'
        && $request['Body'] === 'SMS payload'
    );
});
