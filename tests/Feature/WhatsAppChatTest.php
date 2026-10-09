<?php

use App\Livewire\WhatsAppChat;
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

    test('shop actions do not grant credits or services without payment processing', function () {
        Livewire::test(WhatsAppChat::class)
        ->call('showPanel', 'shop')
        ->assertSet('installedShopItems', [])
        ->call('topUpCredits')
            ->assertSet('installedShopItems', [])
        ->call('purchaseShopProduct', 'credits-5000')
        ->assertSet('installedShopItems', []);
    });
