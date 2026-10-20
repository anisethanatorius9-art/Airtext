<?php

use App\Livewire\WhatsAppChat;
use App\Models\Contact;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Status;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Livewire\Livewire;

test('a contact profile can be opened and its disappearing message preference is set', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('openContactProfile')
        ->assertSet('showContactProfile', true)
        ->call('setDisappearingMessages', '24h')
        ->assertSet('conversationPreferences.1.disappearing', '24h');
});

test('chat selection opens the conversation and emoji can be added to the draft', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('selectConversation', 2)
        ->assertSet('showConversation', true)
        ->call('toggleEmojiPicker')
        ->assertSet('showEmojiPicker', true)
        ->call('insertEmoji', '😂')
        ->assertSet('messageDraft', '😂')
        ->call('backToChats')
        ->assertSet('showConversation', false)
        ->assertSet('showEmojiPicker', false);
});

test('blocked contacts cannot receive a new local message and their chat can be cleared', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('toggleBlockContact')
        ->set('messageDraft', 'This should not be sent')
        ->call('sendMessage')
        ->assertSet('messageDraft', 'This should not be sent')
        ->call('toggleBlockContact')
        ->call('clearChat')
        ->assertSet('conversations.0.messages', []);
});

test('storage manager clears only owned SMS messages and preserves shared or other-user data', function () {
    Storage::fake('local');
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $smsConversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'name' => 'SMS contact',
        'phone_number' => '+255700000001',
    ]);
    $sharedConversation = Conversation::query()->create([
        'owner_id' => $user->id,
        'recipient_id' => $otherUser->id,
        'name' => 'Shared chat',
    ]);
    $otherConversation = Conversation::query()->create([
        'owner_id' => $otherUser->id,
        'name' => 'Other user SMS',
        'phone_number' => '+255700000002',
    ]);
    $smsMediaPath = 'voice-messages/'.$user->id.'/sms.wav';
    $sharedMediaPath = 'voice-messages/'.$user->id.'/shared.wav';
    Storage::disk('local')->put($smsMediaPath, 'sms voice');
    Storage::disk('local')->put($sharedMediaPath, 'shared voice');
    $smsMessage = $smsConversation->messages()->create([
        'sender_id' => $user->id,
        'direction' => 'outbound',
        'body' => 'SMS history',
        'media_path' => $smsMediaPath,
    ]);
    $smsSharedMediaMessage = $smsConversation->messages()->create([
        'sender_id' => $user->id,
        'direction' => 'outbound',
        'body' => 'Shared media reference',
        'media_path' => $sharedMediaPath,
    ]);
    $sharedMessage = $sharedConversation->messages()->create([
        'sender_id' => $user->id,
        'direction' => 'outbound',
        'body' => 'Shared history',
        'media_path' => $sharedMediaPath,
    ]);
    $otherMessage = $otherConversation->messages()->create([
        'sender_id' => $otherUser->id,
        'direction' => 'outbound',
        'body' => 'Other history',
    ]);

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->call('openSettings')
        ->call('selectSetting', 'storage')
        ->assertSee('Storage and data')
        ->call('openStorageDetails')
        ->assertSee('SMS contact')
        ->call('clearStoredSmsConversation', $smsConversation->id);

    expect(Message::query()->find($smsMessage->id))->toBeNull()
        ->and(Message::query()->find($smsSharedMediaMessage->id))->toBeNull()
        ->and(Message::query()->find($sharedMessage->id))->not->toBeNull()
        ->and(Message::query()->find($otherMessage->id))->not->toBeNull()
        ->and(Storage::disk('local')->exists($smsMediaPath))->toBeFalse()
        ->and(Storage::disk('local')->exists($sharedMediaPath))->toBeTrue();
});

    test('a guest can render storage settings without account data', function () {
        Livewire::test(WhatsAppChat::class)
        ->call('openSettings')
        ->call('selectSetting', 'storage')
        ->assertSee('Storage and data')
        ->assertSee('Network usage')
        ->assertSee('0 B');
    });

test('storage preferences are validated and saved to the signed-in account', function () {
    $user = User::factory()->create([
        'storage_settings' => ['auto_download_photos' => false],
    ]);

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->call('openSettings')
        ->call('selectSetting', 'storage')
        ->assertSee('Network usage')
        ->assertSee('Media display')
        ->assertSee('Detecting this device...')
        ->call('openStorageDetails')
        ->assertSee('Clear all SMS messages')
        ->call('backFromStorageSettings')
        ->assertSee('Auto-download quality')
        ->set('useLessDataForCalls', true)
        ->set('uploadQuality', 'standard')
        ->set('autoDownloadQuality', 'high')
        ->set('mobileDataDownloads', 'none')
        ->set('wifiDownloads', 'all')
        ->set('roamingDownloads', 'photos')
        ->call('saveStorageSettings');

    expect($user->fresh()->storage_settings)->toBe([
        'auto_download_photos' => false,
        'use_less_data_for_calls' => true,
        'upload_quality' => 'standard',
        'auto_download_quality' => 'high',
        'mobile_data_downloads' => 'none',
        'wifi_downloads' => 'all',
        'roaming_downloads' => 'photos',
    ]);

    Livewire::actingAs($user->fresh())
        ->test(WhatsAppChat::class)
        ->assertSet('useLessDataForCalls', true)
        ->assertSet('uploadQuality', 'standard')
        ->assertSet('autoDownloadQuality', 'high')
        ->assertSet('mobileDataDownloads', 'none')
        ->assertSet('wifiDownloads', 'all')
        ->assertSet('roamingDownloads', 'photos');
});

test('network usage and proxy rows open their own working detail pages', function () {
    $user = User::factory()->create();
    DB::table('user_network_usage')->insert([
        'user_id' => $user->id,
        'period_start' => now()->startOfMonth()->toDateString(),
        'uploaded_bytes' => 1536,
        'downloaded_bytes' => 2048,
        'request_count' => 9,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->call('openSettings')
        ->call('selectSetting', 'storage')
        ->assertSee('Media display')
        ->assertSee('Detecting this device...')
        ->call('openNetworkDetails')
        ->assertSee('Network usage')
        ->assertSee('1.5 KB')
        ->assertSee('2.0 KB')
        ->assertSee('9')
        ->call('backFromStorageSettings')
        ->call('openProxyDetails')
        ->assertSee('Proxy is controlled by your browser or device.')
        ->assertSee('Check connection');
});

test('a selected image is saved privately and only its owner can view it', function () {
    Storage::fake('local');
    $user = User::factory()->create(['phone_number' => '+255712884102']);
    $otherUser = User::factory()->create();

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->set('messageAttachment', UploadedFile::fake()->image('receipt.png'))
        ->call('sendMessage')
        ->assertSet('messageAttachment', null)
        ->assertSee('receipt.png');

    $message = Message::query()
        ->where('sender_id', $user->id)
        ->where('message_type', 'image')
        ->firstOrFail();
    $conversation = Conversation::query()->findOrFail($message->conversation_id);

    expect($message->status)->toBe('failed')
        ->and(Storage::disk('local')->exists($message->media_path))->toBeTrue();

    $this->actingAs($user)
        ->get(route('chat.attachments.show', ['conversation' => $conversation, 'message' => $message]))
        ->assertOk();

    $this->actingAs($otherUser)
        ->get(route('chat.attachments.show', ['conversation' => $conversation, 'message' => $message]))
        ->assertNotFound();

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->set('messageAttachment', UploadedFile::fake()->create('invoice.pdf', 24, 'application/pdf'))
        ->call('sendMessage')
        ->assertSet('messageAttachment', null)
        ->assertSee('invoice.pdf');

    $document = Message::query()
        ->where('sender_id', $user->id)
        ->where('message_type', 'document')
        ->firstOrFail();
    expect(Storage::disk('local')->exists($document->media_path))->toBeTrue();
});

test('signed-in web requests are included in network usage', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->get('/')->assertOk();
    $usage = DB::table('user_network_usage')
        ->where('user_id', $user->id)
        ->where('period_start', now()->startOfMonth()->toDateString())
        ->first();

    expect($usage)->not->toBeNull()
        ->and($usage->request_count)->toBe(1)
        ->and($usage->downloaded_bytes)->toBe(strlen((string) $response->getContent()));
});

test('disappearing message durations and reports are constrained to supported values', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('setDisappearingMessages', 'forever')
        ->assertSet('conversationPreferences', [])
        ->call('reportContact')
        ->assertSet('conversationPreferences.1.reported', true);
});

test('expired messages are hidden from the active conversation', function () {
    Livewire::test(WhatsAppChat::class)
        ->set('conversations.0.messages.0.expires_at', now()->subMinute()->toIso8601String())
        ->assertDontSee('Can you give me the payload code for AirText SMS parsing?');
});

test('channels are nested under updates while groups remain in chats', function () {
    Livewire::test(WhatsAppChat::class)
        ->assertSee('Groups')
        ->assertDontSee('aria-label="Channels"', false)
        ->call('showPanel', 'status')
        ->assertSee('Status')
        ->assertSee('Channels')
        ->call('showPanel', 'channels')
        ->assertSee('Create a channel');
});

test('opening the new contact flow goes directly to the real composer', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('openContactForm')
        ->assertSet('showWebContactNotice', false)
        ->assertSet('showContactForm', true);
});

test('an authenticated user can update privacy visibility preferences from settings', function () {
    $user = User::factory()->create([
        'last_seen_visibility' => 'Everyone',
        'profile_picture_visibility' => 'My contacts',
        'status_visibility' => 'Everyone',
    ]);

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->set('lastSeenVisibility', 'My contacts')
        ->set('profilePictureVisibility', 'Nobody')
        ->set('statusVisibility', 'My contacts')
        ->call('savePrivacySettings')
        ->assertSet('lastSeenVisibility', 'My contacts')
        ->assertSet('profilePictureVisibility', 'Nobody')
        ->assertSet('statusVisibility', 'My contacts');

    expect($user->fresh()->last_seen_visibility)->toBe('My contacts')
        ->and($user->fresh()->profile_picture_visibility)->toBe('Nobody')
        ->and($user->fresh()->status_visibility)->toBe('My contacts');
});

test('an authenticated user can upload a profile photo from settings', function () {
    $user = User::factory()->create();

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->set('profilePhoto', UploadedFile::fake()->image('avatar.png', 320, 320))
        ->call('uploadProfilePhoto')
        ->assertSet('profilePhotoUrl', fn (string $url) => str_contains($url, 'profile-photos'))
        ->assertSet('profilePhoto', null);

    expect($user->fresh()->profile_photo_path)->not->toBeNull();
});

test('status viewers can see view-once and screenshot protection metadata and like a story', function () {
    $owner = User::factory()->create(['name' => 'Miriam']);
    $viewer = User::factory()->create(['name' => 'Nina']);
    $status = Status::query()->create([
        'user_id' => $owner->id,
        'body' => 'Launch day update',
        'media_type' => 'text',
        'privacy' => 'Contacts',
        'view_once' => true,
        'screenshot_protected' => true,
        'background' => '#00a884',
        'font' => 'sans',
        'author_name' => $owner->name,
        'author_initials' => 'MI',
        'is_viewed' => false,
        'expires_at' => now()->addDay(),
    ]);
    $status->viewers()->attach($viewer->id, ['viewed_at' => now()]);

    Livewire::actingAs($viewer)
        ->test(WhatsAppChat::class)
        ->call('showPanel', 'status')
        ->call('openStatus', $status->id)
        ->assertSee('View once')
        ->assertSee('Screenshot protected')
        ->assertSee('1 viewer')
        ->call('toggleStatusLike')
        ->assertSet('statusLiked', true)
        ->assertSee('Liked');
});

test('switching panels closes transient overlays so the app feels fluid', function () {
    Livewire::test(WhatsAppChat::class)
        ->set('showContactForm', true)
        ->set('showSettings', true)
        ->set('showDialpad', true)
        ->call('showPanel', 'status')
        ->assertSet('showContactForm', false)
        ->assertSet('showSettings', false)
        ->assertSet('showDialpad', false);
});

test('the chat favourites filter only shows favorite conversations', function () {
    Livewire::test(WhatsAppChat::class)
        ->set('filter', 'Favourites')
        ->assertSet('filteredConversations', fn (array $conversations) => count($conversations) === 1 && $conversations[0]['name'] === 'Juma K.');
});

test('the marketplace browse section is seeded with featured products', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('showPanel', 'shop')
        ->assertSet('shopProducts', fn (array $products) => count($products) > 0)
        ->assertSet('filteredShopProducts.0.name', 'Tourism SMS Bot')
        ->assertSet('filteredShopProducts.1.name', 'Gateway Recovery Suite');
});

test('the marketplace shows a helpful empty state when no extensions are installed yet', function () {
    $user = User::factory()->create();

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->call('showPanel', 'shop')
        ->assertSee('No installed services yet');
});

test('the marketplace shows a helpful no-results state when filters hide every product', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('showPanel', 'shop')
        ->set('shopSearch', 'totally-missing-service')
        ->assertSee('No products match your search');
});

test('a valid marketplace product can be installed after a configured checkout is available', function () {
    config()->set('services.azampay', ['token' => 'demo-token', 'base_url' => 'https://example.test']);

    $user = User::factory()->create();

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->call('showPanel', 'shop')
        ->call('purchaseShopProduct', 'tourism-sms-bot')
        ->assertSet('installedShopItems.0.name', 'Tourism SMS Bot')
        ->assertSet('installedShopItems.0.status', 'Active')
        ->assertSet('filteredShopProducts.0.is_installed', true)
        ->assertSee('Installed');

    expect($user->shopTransactions()->count())->toBe(1)
        ->and($user->installedBots()->count())->toBe(1);
});

test('system notices can be dismissed for the current session', function () {
    $this->travelTo(\Illuminate\Support\Carbon::parse('2026-10-15 12:00:00', 'UTC'));

    Livewire::test(WhatsAppChat::class)
        ->call('showPanel', 'notifications')
        ->assertSee('Upcoming maintenance')
        ->assertSee('Policy update')
        ->call('dismissSystemNotification', 'policy-update-2026-10')
        ->assertDontSee('Policy update')
        ->assertSee('Upcoming maintenance');

    Livewire::test(WhatsAppChat::class)
        ->call('showPanel', 'notifications')
        ->assertDontSee('Policy update')
        ->assertSee('Upcoming maintenance');

    $this->travelBack();
});

test('service renewal notices use the signed-in users actual expiry date', function () {
    $user = User::factory()->create();
    $plan = SubscriptionPlan::query()->where('code', 'pro_monthly')->firstOrFail();
    Subscription::query()->create([
        'user_id' => $user->id,
        'subscription_plan_id' => $plan->id,
        'status' => 'active',
        'activated_at' => now()->subDays(27),
        'ends_at' => now()->addDays(3),
    ]);

    Livewire::actingAs($user)
        ->test(WhatsAppChat::class)
        ->call('showPanel', 'notifications')
        ->assertSee('Subscription expiring soon')
        ->assertSee('Pro Pass')
        ->assertSee('Renew now')
        ->call('openSubscriptionPlans')
        ->assertSet('leftPanel', 'shop')
        ->assertSet('shopSection', 'subscriptions')
        ->assertSee('Choose your plan');
});

test('favorite contacts become visible in the calls panel after being added', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('showPanel', 'calls')
        ->call('addFavorite', '+255 782 328 215')
        ->assertSet('favorites.0.name', 'Unknown number')
        ->assertSee('Unknown number');
});

test('saving a contact does not duplicate an existing conversation for the same number', function () {
    $phone = '+255712000111';
    $existing = Contact::query()->create([
        'name' => 'Amina Yusuf',
        'phone_number' => $phone,
        'status_bio' => 'SMS contact',
        'payload_prefix' => 'MSG:',
        'is_registered' => true,
    ]);
    $conversation = Conversation::query()->create([
        'phone_number' => $phone,
        'name' => 'Amina Yusuf',
    ]);

    Livewire::test(WhatsAppChat::class)
        ->set('contactFirstName', 'Amina')
        ->set('contactLastName', 'Yusuf')
        ->set('contactPhone', $phone)
        ->call('saveContact')
        ->assertSet('activeConversationId', $conversation->id)
        ->assertSet('conversations', fn (array $conversations) => collect($conversations)->where('id', $conversation->id)->count() === 1);

    expect(Contact::query()->where('phone_number', $phone)->count())->toBe(1)
        ->and(Conversation::query()->where('phone_number', $phone)->count())->toBe(1);
});

test('opening favorites or the dialpad closes other call overlays so one flow remains active', function () {
    Livewire::test(WhatsAppChat::class)
        ->set('showDialpad', true)
        ->set('showCallScreen', true)
        ->call('openFavoritePicker')
        ->assertSet('showDialpad', false)
        ->assertSet('showCallScreen', false)
        ->assertSet('showFavoritePicker', true)
        ->call('openDialpad')
        ->assertSet('showFavoritePicker', false)
        ->assertSet('showDialpad', true)
        ->assertSet('showCallScreen', false);
});

test('active conversation shows live typing and presence states in the header', function () {
    Livewire::test(WhatsAppChat::class)
        ->call('selectConversation', 2)
        ->assertSee('typing')
        ->assertSee('last seen 3m ago');
});

    test('shop actions do not grant products without verified payment', function () {
        $user = \App\Models\User::factory()->create();

        Livewire::actingAs($user)
            ->test(WhatsAppChat::class)
            ->call('showPanel', 'shop')
            ->assertSet('installedShopItems', [])
            ->call('topUpCredits')
            ->call('purchaseShopProduct', 'tourism-bot')
            ->assertSet('installedShopItems', []);

        expect($user->shopTransactions()->count())->toBe(0)
            ->and($user->installedBots()->count())->toBe(0);
    });

    test('subscription shop lists the plans stored in the database', function () {
        Livewire::test(WhatsAppChat::class)
            ->call('showPanel', 'shop')
            ->call('showShopSection', 'subscriptions')
            ->assertSee('Choose your plan')
            ->assertSee('Free Starter')
            ->assertSee('Pro Pass')
            ->assertSee('Business Unlimited')
            ->assertSee('Enterprise · Annual')
            ->assertSee('TZS 10,000')
            ->assertSee('TZS 25,000')
            ->assertSee('TZS 50,000')
            ->assertSee('TZS 450,000');
    });

    test('an authenticated user can activate the free starter subscription', function () {
        $user = User::factory()->create();

        Livewire::actingAs($user)
            ->test(WhatsAppChat::class)
            ->call('showPanel', 'shop')
            ->call('showShopSection', 'subscriptions')
            ->call('chooseSubscriptionPlan', 'free_starter')
            ->assertSee('Subscription active')
            ->assertSee('Your Free Starter plan is active with no expiry date.');

        $subscription = $user->subscriptions()->with('plan')->firstOrFail();
        expect($subscription->status)->toBe('active')
            ->and($subscription->ends_at)->toBeNull()
            ->and($subscription->plan->code)->toBe('free_starter');
    });

    test('free users can upgrade and paid users can renew their current plan', function () {
        $freeUser = User::factory()->create();
        $freePlan = SubscriptionPlan::query()->where('code', 'free_starter')->firstOrFail();
        $proPlan = SubscriptionPlan::query()->where('code', 'pro_monthly')->firstOrFail();
        $freeUser->subscriptions()->create([
            'subscription_plan_id' => $freePlan->id,
            'status' => 'active',
            'activated_at' => now()->subDay(),
        ]);

        Livewire::actingAs($freeUser)
            ->test(WhatsAppChat::class)
            ->call('showPanel', 'shop')
            ->call('showShopSection', 'subscriptions')
            ->call('chooseSubscriptionPlan', 'pro_monthly')
            ->assertSet('showSubscriptionCheckout', true)
            ->assertSet('selectedSubscriptionPlanCode', 'pro_monthly')
            ->assertSee('TZS 10,000');

        $paidUser = User::factory()->create();
        $paidUser->subscriptions()->create([
            'subscription_plan_id' => $proPlan->id,
            'status' => 'active',
            'activated_at' => now()->subDays(27),
            'ends_at' => now()->addDays(3),
        ]);

        Livewire::actingAs($paidUser)
            ->test(WhatsAppChat::class)
            ->call('showPanel', 'shop')
            ->call('showShopSection', 'subscriptions')
            ->assertSee('Renew plan')
            ->call('chooseSubscriptionPlan', 'pro_monthly')
            ->assertSet('showSubscriptionCheckout', true);
    });
