<div class="whatsapp-app {{ $showConversation ? 'show-conversation' : '' }}">
    <aside class="whatsapp-rail">
        <a href="{{ route('home') }}" class="rail-brand" aria-label="Air app home"><x-app-logo-icon /></a>
        <div class="rail-top">
            <flux:button wire:click="showPanel('chats')" variant="ghost" icon="chat-bubble-left-right" square aria-label="Chats" />
            <flux:button wire:click="showPanel('calls')" variant="ghost" icon="phone" square aria-label="Calls" />
            <flux:button wire:click="showPanel('status')" variant="ghost" icon="globe-alt" square aria-label="Updates" />
            <flux:button wire:click="showPanel('contacts')" variant="ghost" icon="users" square aria-label="Contacts" />
            <flux:button variant="ghost" icon="user-group" square aria-label="Communities and groups" />
        </div>
        <div class="rail-separator" aria-hidden="true"></div>
        <div class="rail-services">
            <flux:button wire:click="showPanel('shop')" variant="ghost" icon="building-storefront" square aria-label="AirText Shop and SMS services" />
            <flux:button wire:click="showPanel('notifications')" variant="ghost" icon="bell-alert" square aria-label="AirText announcements" />
        </div>
        <div class="rail-spacer"></div>
        <div class="rail-media">
            <flux:button variant="ghost" icon="photo" square aria-label="Media and document vault" />
        </div>
        <div class="rail-bottom">
            <flux:button wire:click="openSettings" variant="ghost" icon="cog-6-tooth" square aria-label="Settings" />
            <flux:avatar initials="A" color="green" size="sm" />
        </div>
    </aside>

    <aside class="whatsapp-chats">
        @if($leftPanel === 'shop')
        <div class="shop-context-panel">
            <div class="shop-context-mark"><flux:icon.building-storefront variant="outline" /></div>
            <flux:heading size="lg">AirText Shop</flux:heading>
            <flux:text>Marketplace</flux:text>
            <div class="shop-context-links"><span class="is-active"><flux:icon.squares-2x2 variant="outline" /> Browse services</span><span><flux:icon.shopping-bag variant="outline" /> Installed items</span><span>
                    <flux:icon.wallet variant="outline" /> Wallet & billing
                </span></div>
        </div>
        @elseif($leftPanel === 'status')
        @include('livewire.status-sidebar')
        @elseif($leftPanel === 'calls')
        <header class="chats-header calls-header">
            <flux:heading size="xl">Calls</flux:heading>
            <div class="header-actions">
                <flux:button wire:click="openDialpad" variant="ghost" icon="squares-2x2" square aria-label="Open dialpad" />
                <flux:button wire:click="openDialpad" variant="ghost" icon="phone" square aria-label="New call" />
            </div>
        </header>
        <div class="panel-search calls-search">
            <flux:input wire:model.live="search" icon="magnifying-glass" placeholder="Search name, number or @username" />
        </div>
        <div class="calls-content">
            <section class="favorites-section" aria-labelledby="favorites-heading">
                <h2 id="favorites-heading" class="calls-section-label">Favorites</h2>
                <button type="button" wire:click="openFavoritePicker" class="favorite-action"><span class="favorite-action-icon"><flux:icon.user-plus variant="outline" /></span><span>Add favorite</span></button>
                @if($favorites)
                <div class="favorite-list" aria-label="Favorite contacts">
                    @foreach($favorites as $favorite)
                    @php($initials = collect(explode(' ', trim($favorite['name'])))->map(fn ($part) => strtoupper(substr($part, 0, 1)))->take(2)->join('') ?: '★')
                    <div class="favorite-person">
                        <flux:avatar initials="{{ $initials }}" color="zinc" size="sm" />
                        <span>
                            <strong>{{ $favorite['name'] }}</strong>
                            <small>{{ $favorite['number'] }}</small>
                        </span>
                        <button type="button" wire:click="removeFavorite('{{ $favorite['number'] }}')" class="remove-favorite" aria-label="Remove {{ $favorite['name'] }} from favorites">
                            <flux:icon.x-mark variant="outline" />
                        </button>
                    </div>
                    @endforeach
                </div>
                @endif
            </section>
            <section class="recent-calls-section" aria-labelledby="recent-calls-heading">
                <h2 id="recent-calls-heading" class="calls-section-label">Recent</h2>
                <nav class="chat-list" aria-label="Recent call logs">
                    @forelse($this->filteredCalls as $call)
                    <article class="call-list-item {{ $call['missed'] ? 'is-missed' : '' }}">
                        <flux:avatar initials="{{ $call['initials'] }}" color="zinc" size="md" />
                        <div class="call-copy">
                            <strong>{{ $call['name'] }}</strong>
                            <span class="call-type {{ $call['missed'] ? 'is-missed' : '' }}">
                                <flux:icon name="{{ $call['direction'] === 'outbound' ? 'arrow-up-right' : 'arrow-down-left' }}" variant="outline" /> {{ $call['missed'] ? 'Missed call' : ($call['direction'] === 'outbound' ? 'Outgoing call' : 'Incoming call') }}
                            </span>
                            <small>{{ $call['number'] }}</small>
                        </div>
                        <div class="call-meta"><time>{{ $call['time'] }}</time>@if($call['duration'])<small>{{ $call['duration'] }}</small>@endif</div>
                        <button type="button" wire:click="openCallInterface(@js($call['number']), @js($call['name']))" class="quick-call" aria-label="Call {{ $call['name'] }}">
                            <flux:icon.phone />
                        </button>
                    </article>
                    @empty
                    <p class="empty-chats">No recent calls found.</p>
                    @endforelse
                </nav>
            </section>
        </div>
        @elseif($leftPanel === 'contacts')
        <header class="new-chat-header">
            <flux:button wire:click="showPanel('chats')" variant="ghost" icon="arrow-left" square aria-label="Back to chats" />
            <flux:heading size="xl">New chat</flux:heading>
            <flux:dropdown position="bottom" align="end">
                <flux:button variant="ghost" icon="ellipsis-vertical" square aria-label="Contact options" />
                <flux:menu>
                    <flux:menu.item icon="arrow-path">Refresh contacts</flux:menu.item>
                    <flux:menu.item icon="adjustments-horizontal">Contact settings</flux:menu.item>
                </flux:menu>
            </flux:dropdown>
        </header>
        <div class="panel-search contact-search">
            <flux:input wire:model.live="search" icon="magnifying-glass" placeholder="Search name, number or..." />
        </div>
        <div class="contact-quick-actions">
            <button class="contact-action-row"><span class="contact-action-icon">
                    <flux:icon.users variant="outline" />
                </span><span><strong>New group</strong><small>Create group SMS</small></span><flux:icon.chevron-right /></button>
            <button wire:click="openContactForm" class="contact-action-row"><span class="contact-action-icon"><flux:icon.user-plus variant="outline" /></span><span><strong>New contact</strong><small>Create an SMS contact</small></span><flux:icon.chevron-right /></button>
        </div>
        <button wire:click="selectConversation(1)" class="contact-owner-card">
            <flux:avatar initials="A" color="green" size="md" /><span><strong>{{ $displayName }} <em>You</em></strong><small>{{ $phoneNumber }} · Message yourself</small></span><flux:icon.chevron-right />
        </button>
        <nav class="chat-list contact-directory" aria-label="Contacts on AirText">
            <p class="contact-section-label">Contacts on AirText</p>
            @forelse($this->registeredContacts as $contact)
            <button class="chat-list-item" wire:click="selectContact({{ $contact['id'] }})">
                <flux:avatar initials="{{ $contact['initials'] }}" color="zinc" size="md" /><span class="chat-list-copy"><strong>{{ $contact['name'] }}</strong><span>{{ $contact['phone_number'] }}</span><small class="contact-status">{{ $contact['status'] }}</small></span>
            </button>
            @empty
            <p class="empty-chats">No registered AirText contacts found.</p>
            @endforelse
            <p class="contact-section-label invite-section-label">Invite to AirText</p>
            @forelse($this->inviteContacts as $contact)
            @php($inviteLink = 'https://airtext.app/invite?ref='.preg_replace('/\s+/', '', $contact['phone_number']))
            <article class="chat-list-item invite-contact-row">
                <flux:avatar initials="{{ $contact['initials'] }}" color="zinc" size="md" /><span class="chat-list-copy"><strong>{{ $contact['name'] }}</strong><span>{{ $contact['phone_number'] }}</span></span><a class="invite-button" href="sms:{{ preg_replace('/\s+/', '', $contact['phone_number']) }}?body={{ urlencode('Join me on AirText: '.$inviteLink) }}" aria-label="Invite {{ $contact['name'] }}">Invite</a>
            </article>
            @empty
            <p class="empty-chats">All synced contacts are on AirText.</p>
            @endforelse
        </nav>
        @elseif($leftPanel === 'channels')
        <header class="chats-header">
            <flux:heading size="xl">Updates</flux:heading>
            <flux:button wire:click="openChannelComposer" variant="ghost" icon="plus" square aria-label="Create channel" />
        </header>
        <div class="chat-filters" role="tablist" aria-label="Updates">
            <button wire:click="showPanel('status')" class="chat-filter" role="tab" aria-selected="false">Status</button>
            <button wire:click="showPanel('channels')" class="chat-filter is-active" role="tab" aria-selected="true">Channels</button>
        </div>
        <div class="panel-search">
            <flux:input wire:model.live="search" icon="magnifying-glass" placeholder="Discover channels" />
        </div>
        <button type="button" wire:click="openChannelComposer" class="add-contact-row">
            <flux:icon.megaphone variant="outline" /><span><strong>Create a channel</strong><small>Broadcast updates by SMS</small></span><flux:icon.chevron-right />
        </button>
        <nav class="chat-list" aria-label="Subscribed channels">
            @forelse($this->channelList as $channel)
            <button type="button" class="chat-list-item">
                <flux:avatar initials="{{ $channel['initials'] }}" color="zinc" size="md" /><span class="chat-list-copy"><strong>{{ $channel['name'] }}</strong><span>{{ $channel['announcement'] }}</span></span>
            </button>
            @empty
            <p class="empty-chats">No channels found yet.</p>
            @endforelse
        </nav>
        @if($showChannelComposer)
        <div class="calls-modal-backdrop">
            <section class="calls-modal" role="dialog" aria-modal="true" aria-labelledby="channel-composer-title">
                <header class="calls-modal-header">
                    <flux:heading id="channel-composer-title" size="lg">Create channel</flux:heading>
                    <flux:button wire:click="closeChannelComposer" variant="ghost" icon="x-mark" square aria-label="Close channel composer" />
                </header>
                <form wire:submit="createChannel" class="contact-form">
                    <flux:field>
                        <flux:label>Channel name</flux:label>
                        <flux:input wire:model="channelName" placeholder="AirText Updates" />
                        @error('channelName')<flux:error>{{ $message }}</flux:error>@enderror
                    </flux:field>
                    <flux:field>
                        <flux:label>Description</flux:label>
                        <flux:textarea wire:model="channelDescription" placeholder="What should people expect here?" rows="4" />
                        @error('channelDescription')<flux:error>{{ $message }}</flux:error>@enderror
                    </flux:field>
                    <div class="contact-notice-actions">
                        <flux:button type="button" wire:click="closeChannelComposer" variant="ghost">Cancel</flux:button>
                        <flux:button type="submit" variant="primary">Create</flux:button>
                    </div>
                </form>
            </section>
        </div>
        @endif
        @else
        <header class="chats-header">
            <flux:heading size="xl">Chats</flux:heading>
            <div class="header-actions">
                <flux:button wire:click="showPanel('contacts')" variant="ghost" icon="plus" square aria-label="New chat" />
                <flux:dropdown position="bottom" align="end">
                    <flux:button variant="ghost" icon="ellipsis-vertical" square aria-label="Chat menu" />
                    <flux:menu>
                        <flux:menu.item wire:click="openContactForm" icon="user-plus">New contact</flux:menu.item>
                        <flux:menu.item icon="archive-box">Archived chats</flux:menu.item>
                    </flux:menu>
                </flux:dropdown>
            </div>
        </header>
        <div class="chat-search">
            <flux:input wire:model.live.debounce.250ms="search" icon="magnifying-glass" placeholder="Search or start a new chat" />
        </div>
        <div class="chat-filters" role="tablist" aria-label="Chat filters">@foreach(['All', 'Unread', 'Favourites', 'Groups'] as $chatFilter)<button wire:click="$set('filter', '{{ $chatFilter }}')" class="chat-filter {{ $filter === $chatFilter ? 'is-active' : '' }}" role="tab" aria-selected="{{ $filter === $chatFilter ? 'true' : 'false' }}">{{ $chatFilter }}</button>@endforeach</div>
        <nav class="chat-list" aria-label="Conversations">@forelse($this->filteredConversations as $conversation)<button wire:key="conversation-{{ $conversation['id'] }}" wire:click="selectConversation({{ $conversation['id'] }})" class="chat-list-item {{ $activeConversationId === $conversation['id'] ? 'is-selected' : '' }}">
                <flux:avatar initials="{{ $conversation['initials'] }}" color="zinc" size="md" /><span class="chat-list-copy"><strong>{{ $conversation['name'] }}</strong><span>{{ $conversation['preview'] }}</span></span><span class="chat-list-meta"><time>{{ $conversation['time'] }}</time>@if($conversation['unread'])<b>{{ $conversation['unread'] }}</b>@endif</span>
            </button>@empty<p class="empty-chats">No conversations found.</p>@endforelse</nav>
        @endif
        @if($showFavoritePicker)
        <div class="calls-modal-backdrop">
            <section class="calls-modal" role="dialog" aria-modal="true" aria-labelledby="favorite-picker-title">
                <header class="calls-modal-header">
                    <flux:heading id="favorite-picker-title" size="lg">Add favorite</flux:heading>
                    <flux:button wire:click="closeFavoritePicker" variant="ghost" icon="x-mark" square aria-label="Close favorite picker" />
                </header>
                <flux:text>Select a person from your recent calls.</flux:text>
                <div class="favorite-picker-list">
                    @foreach($calls as $call)
                    <button type="button" wire:click="addFavorite('{{ $call['number'] }}')" class="favorite-picker-item">
                        <flux:avatar initials="{{ $call['initials'] }}" color="zinc" size="md" />
                        <span><strong>{{ $call['name'] }}</strong><small>{{ $call['number'] }}</small></span>
                        <flux:icon name="star" variant="outline" />
                    </button>
                    @endforeach
                </div>
            </section>
        </div>
        @endif
        @if($showDialpad)
        <div class="calls-modal-backdrop">
            <section class="calls-modal dialpad-modal" role="dialog" aria-modal="true" aria-labelledby="dialpad-title">
                <header class="calls-modal-header">
                    <flux:heading id="dialpad-title" size="lg">New call</flux:heading>
                    <flux:button wire:click="closeDialpad" variant="ghost" icon="x-mark" square aria-label="Close dialpad" />
                </header>
                <flux:input wire:model.live="dialNumber" inputmode="tel" autocomplete="tel" placeholder="Enter phone number" aria-label="Phone number" />
                <div class="dialpad-display-actions">
                    <flux:text>{{ $dialNumber ?: 'Enter a number' }}</flux:text>
                    <flux:button wire:click="clearDialNumber" variant="ghost" icon="backspace" square aria-label="Clear number" />
                </div>
                <div class="dialpad-grid" aria-label="Dialpad">
                    @foreach(['1' => '', '2' => 'ABC', '3' => 'DEF', '4' => 'GHI', '5' => 'JKL', '6' => 'MNO', '7' => 'PQRS', '8' => 'TUV', '9' => 'WXYZ', '*' => '', '0' => '+', '#' => ''] as $digit => $letters)
                    <button type="button" wire:click="appendDialDigit('{{ $digit }}')" class="dialpad-key">
                        <strong>{{ $digit }}</strong>
                        @if($letters)<small>{{ $letters }}</small>@endif
                    </button>
                    @endforeach
                </div>
                <div class="dialpad-actions">
                    <flux:button wire:click="removeDialDigit" variant="ghost" icon="backspace" square aria-label="Delete last digit" />
                    <flux:button wire:click="startCall" type="button" variant="primary" icon="phone" class="dial-button" :disabled="$dialNumber === ''" aria-label="Call {{ $dialNumber ?: 'number' }}" />
                </div>
            </section>
        </div>
        @endif
        @if($showCallScreen)
        <div class="call-screen-backdrop">
            <section class="call-screen" role="dialog" aria-modal="true" aria-labelledby="call-screen-name">
                <header class="call-screen-header">
                    <flux:button wire:click="closeCallInterface" variant="ghost" icon="arrow-down" square aria-label="Close call screen" />
                    <span class="call-screen-encryption"><flux:icon.lock-closed /> AirText call</span>
                    <span class="call-screen-spacer"></span>
                </header>
                <div class="call-screen-person">
                    <flux:avatar initials="{{ collect(preg_split('/\s+/', trim($callName)))->filter()->take(2)->map(fn ($part) => mb_substr($part, 0, 1))->implode('') ?: '?' }}" color="zinc" size="xl" />
                    <flux:heading id="call-screen-name" size="xl">{{ $callName }}</flux:heading>
                    <flux:text>{{ $callNumber }}</flux:text>
                    <span class="call-screen-status">Ready to call</span>
                </div>
                <div class="call-screen-controls">
                    <button type="button" wire:click="toggleCallControl('speaker')" class="call-screen-control {{ $callSpeaker ? 'is-active' : '' }}" aria-pressed="{{ $callSpeaker ? 'true' : 'false' }}">
                        <span><flux:icon.speaker-wave /></span><small>Speaker</small>
                    </button>
                    <button type="button" wire:click="toggleCallControl('video')" class="call-screen-control {{ $callVideo ? 'is-active' : '' }}" aria-pressed="{{ $callVideo ? 'true' : 'false' }}">
                        <span><flux:icon.video-camera /></span><small>Video</small>
                    </button>
                    <button type="button" wire:click="toggleCallControl('mute')" class="call-screen-control {{ $callMuted ? 'is-active' : '' }}" aria-pressed="{{ $callMuted ? 'true' : 'false' }}">
                        <span>
                            <flux:icon.microphone />
                        </span><small>{{ $callMuted ? 'Unmute' : 'Mute' }}</small>
                    </button>
                    <button type="button" wire:click="toggleCallControl('more')" class="call-screen-control" aria-expanded="{{ $callMoreOpen ? 'true' : 'false' }}">
                        <span><flux:icon.ellipsis-horizontal /></span><small>More</small>
                    </button>
                    <button type="button" wire:click="shareCallNumber" class="call-screen-control">
                        <span>
                            <flux:icon.share />
                        </span><small>Share</small>
                    </button>
                    <button type="button" wire:click="closeCallInterface" class="call-screen-control is-end">
                        <span>
                            <flux:icon.phone />
                        </span><small>End</small>
                    </button>
                </div>
                @if($callMoreOpen)
                <div class="call-screen-more">
                    <span>Call options</span>
                    <flux:button wire:click="shareCallNumber" variant="ghost" icon="share">Share number</flux:button>
                    <flux:button wire:click="closeCallInterface" variant="ghost" icon="phone">End call</flux:button>
                </div>
                @endif
                <div class="call-screen-actions">
                    <flux:button wire:click="handoffCall" variant="primary" icon="phone" class="call-screen-start">Call using phone</flux:button>
                    <flux:text size="sm">Your phone app handles the live call and audio controls.</flux:text>
                </div>
            </section>
        </div>
        @endif
        @if($showContactForm)
        <section class="contact-form-panel">
            <header class="chats-header">
                <flux:button wire:click="closeContactForm" variant="ghost" icon="arrow-left" square aria-label="Back to contacts" />
                <flux:heading size="lg">New contact</flux:heading>
            </header>
            <form wire:submit="saveContact" class="contact-form">
                <flux:avatar initials="?" color="zinc" size="lg" />
                <flux:field>
                    <flux:label>First name</flux:label>
                    <flux:input wire:model="contactFirstName" />@error('contactFirstName')<flux:error>{{ $message }}</flux:error>@enderror
                </flux:field>
                <flux:field>
                    <flux:label>Last name</flux:label>
                    <flux:input wire:model="contactLastName" />@error('contactLastName')<flux:error>{{ $message }}</flux:error>@enderror
                </flux:field>
                <flux:field>
                    <flux:label>GSM phone number</flux:label>
                    <flux:input wire:model="contactPhone" placeholder="+255712884102" />@error('contactPhone')<flux:error>{{ $message }}</flux:error>@enderror
                </flux:field>
                <flux:field>
                    <flux:label>Default payload prefix</flux:label><select wire:model="contactPayloadPrefix" class="settings-select">
                        <option>MSG:</option>
                        <option>STAT:</option>
                        <option>ACK:</option>
                    </select>
                </flux:field>
                <flux:button type="submit" variant="primary" icon="check">Save contact</flux:button>
            </form>
        </section>
        @endif

    </aside>

    <main class="whatsapp-conversation">
        @if($leftPanel === 'shop')
        @include('livewire.shop-content')
        @elseif($leftPanel === 'notifications')
        <section class="notification-center" aria-labelledby="notification-center-heading">
            <header class="conversation-header">
                <div>
                    <flux:heading id="notification-center-heading" size="lg">System notifications</flux:heading>
                    <flux:text>Service updates and account reminders</flux:text>
                </div>
            </header>
            <div class="notification-center-list">
                @forelse($this->systemNotifications as $notification)
                <flux:callout icon="{{ $notification['icon'] }}" variant="secondary" inline>
                    <flux:callout.heading>{{ $notification['heading'] }}</flux:callout.heading>
                    <flux:callout.text>{{ $notification['text'] }}</flux:callout.text>
                    @if($notification['renewable'])
                    <x-slot name="actions">
                        <flux:button wire:click="openSubscriptionPlans" variant="primary">Renew now</flux:button>
                        <flux:button wire:click="openSubscriptionPlans" variant="ghost">View plans</flux:button>
                    </x-slot>
                    @endif
                    <x-slot name="controls">
                        <flux:button wire:click="dismissSystemNotification('{{ $notification['key'] }}')" variant="ghost" icon="x-mark" square aria-label="Dismiss {{ $notification['heading'] }}" />
                    </x-slot>
                </flux:callout>
                @empty
                <div class="empty-chats">You're all caught up.</div>
                @endforelse
            </div>
        </section>
        @elseif($leftPanel === 'status')
        @include('livewire.status-viewer')
        @else
        <header class="conversation-header">
            <flux:button wire:click="backToChats" variant="ghost" icon="arrow-left" square class="conversation-back-button" aria-label="Back to chats" />
            <button type="button" wire:click="openContactProfile" class="conversation-contact" aria-label="Open {{ $this->activeConversation['name'] }} profile">
                <flux:avatar initials="{{ $this->activeConversation['initials'] }}" color="zinc" size="sm" />
                <div><strong>{{ $this->activeConversation['name'] }}</strong><span>
                        @if(($this->activeConversation['typing'] ?? false))
                        typing... · {{ $this->activeConversation['last_seen'] ?? 'last seen recently' }}
                        @elseif(($this->activeConversation['is_online'] ?? false))
                        online
                        @else
                        {{ $this->activeConversation['last_seen'] ?? 'last seen recently' }}
                        @endif
                    </span></div>
            </button>
            <div class="header-actions">
                <flux:button type="button" wire:click="callActiveConversation" variant="ghost" icon="phone" square aria-label="Call contact" />
                <flux:dropdown position="bottom" align="end">
                    <flux:button variant="ghost" icon="ellipsis-vertical" square aria-label="Conversation menu" />
                    <flux:menu>
                        <flux:menu.item wire:click="openContactProfile" icon="information-circle">Contact info</flux:menu.item>
                        <flux:menu.item icon="archive-box">Archive chat</flux:menu.item>
                    </flux:menu>
                </flux:dropdown>
            </div>
        </header>

        <section class="messages-area" aria-label="Messages" wire:poll.30s>
            <div class="message-date">Today</div>
            @if($this->activeConversationPreferences['blocked'])
            <p class="chat-blocked-notice">Messages are blocked for this conversation.</p>
            @endif
            @foreach($this->activeConversation['messages'] as $message)
            <div wire:key="message-{{ $loop->index }}" class="message-line {{ $message['mine'] ? 'is-outgoing' : 'is-incoming' }}">
                <article class="whatsapp-message">
                    @if(!empty($message['code']))
                    <pre class="code-message"><code>{{ $message['body'] }}</code></pre>
                    @elseif(!empty($message['attachment']))
                    @if(!empty($message['attachment_url']) && ($message['attachment_type'] ?? '') === 'image')
                    <a class="image-message-attachment" href="{{ $message['attachment_url'] }}" target="_blank" rel="noopener" aria-label="Open image attachment">
                        <img src="{{ $message['attachment_url'] }}" alt="{{ $message['body'] }}" loading="lazy" />
                    </a>
                    @elseif(!empty($message['attachment_url']))
                    <a class="document-message" href="{{ $message['attachment_url'] }}">
                        <span class="document-icon"><flux:icon.document-text /></span>
                        <span><strong>{{ $message['body'] }}</strong><small>Download attachment</small></span>
                    </a>
                    @else
                    <div class="document-message"><span class="document-icon">▤</span><span><strong>{{ $message['body'] }}</strong><small>1 DOCX · 24 KB</small></span></div>
                    @endif
                    @else
                    <p>{{ $message['body'] }}</p>
                    @endif
                    <small class="message-meta">{{ $message['time'] }} @if(($message['status'] ?? '') === 'failed')<span class="message-failed">Not sent</span>@elseif($message['mine'])<span class="message-checks {{ ($message['status'] ?? 'sent') === 'read' ? 'is-read' : (($message['status'] ?? 'sent') === 'delivered' ? 'is-delivered' : '') }}">{{ ($message['status'] ?? 'sent') === 'read' ? '✓✓' : '✓' }}</span>@endif</small>
                </article>
            </div>
            @endforeach
            <p class="sms-note">Messages are sent over normal SMS. No Wi-Fi or mobile data required.</p>
        </section>

        @if($showEmojiPicker)
        <section class="emoji-picker" aria-label="Emoji picker">
            <header class="emoji-picker-header">
                <strong>Emoji</strong>
                <flux:button type="button" wire:click="toggleEmojiPicker" variant="ghost" icon="x-mark" square aria-label="Close emoji picker" />
            </header>
            <p>Recently used</p>
            <div class="emoji-grid">
                @foreach(['😂', '🙌', '🙂', '🙏', '🤦', '🥹', '🤣', '👍', '❤️', '😍', '😅', '🎉', '😊', '😎', '😢', '🤔', '🔥', '👏', '😘', '💯', '✨', '😴', '🤝', '💚'] as $emoji)
                <button type="button" wire:click="insertEmoji('{{ $emoji }}')" aria-label="Insert {{ $emoji }}">{{ $emoji }}</button>
                @endforeach
            </div>
        </section>
        @endif

        @if($messageAttachment)
        <div class="attachment-upload-preview">
            @if(str_starts_with((string) $messageAttachment->getMimeType(), 'image/'))
            <img src="{{ $messageAttachment->temporaryUrl() }}" alt="Selected image preview" />
            @else
            <span class="attachment-upload-icon"><flux:icon.document-text /></span>
            @endif
            <span class="attachment-upload-copy"><strong>{{ $messageAttachment->getClientOriginalName() }}</strong><small>{{ $this->formatStorageBytes((int) $messageAttachment->getSize()) }}</small></span>
            <flux:button type="button" wire:click="clearMessageAttachment" variant="ghost" icon="x-mark" square aria-label="Remove selected attachment" />
        </div>
        @endif
        @error('messageAttachment')<p class="attachment-upload-error" role="alert">{{ $message }}</p>@enderror

        <form wire:submit="sendMessage" class="message-composer" x-data="{ voiceHint: '' }">
            <div class="composer-entry">
                <flux:button type="button" wire:click="toggleEmojiPicker" variant="ghost" icon="face-smile" square class="emoji-toggle" aria-label="Add emoji" aria-expanded="{{ $showEmojiPicker ? 'true' : 'false' }}" />
                <flux:input wire:model="messageDraft" class="composer-input" placeholder="{{ $this->activeConversationPreferences['blocked'] ? 'Unblock this contact to reply' : 'Message' }}" aria-label="Type a message" :disabled="$this->activeConversationPreferences['blocked']" />
                <div class="composer-media-actions">
                    <flux:button type="button" wire:loading.attr="disabled" wire:target="messageAttachment" x-on:click="$refs.filePicker.click()" variant="ghost" icon="paper-clip" square aria-label="Choose a file" :disabled="$this->activeConversationPreferences['blocked']" />
                    <flux:button type="button" wire:loading.attr="disabled" wire:target="messageAttachment" x-on:click="$refs.cameraPicker.click()" variant="ghost" icon="camera" square aria-label="Take a photo" :disabled="$this->activeConversationPreferences['blocked']" />
                </div>
            </div>
            <input x-ref="filePicker" class="composer-file-input" type="file" accept="image/*,video/*,.pdf,.txt,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.csv,.zip" wire:model="messageAttachment" />
            <input x-ref="cameraPicker" class="composer-file-input" type="file" accept="image/*" capture="environment" wire:model="messageAttachment" />
            <flux:button type="button" class="composer-microphone" variant="primary" icon="microphone" square aria-label="Voice messages are available in the mobile app" title="Voice recording is available in the mobile app" x-on:click="voiceHint = 'Voice recording is available in the mobile app.'" :disabled="$this->activeConversationPreferences['blocked']" />
            <flux:button type="submit" class="composer-send" variant="primary" icon="paper-airplane" square aria-label="Send message" :disabled="$this->activeConversationPreferences['blocked']" />
            <span class="sr-only" aria-live="polite" x-text="voiceHint"></span>
        </form>
        @endif

        @if($showContactProfile && $leftPanel !== 'shop' && $leftPanel !== 'status')
        <aside class="contact-profile-sheet" role="dialog" aria-modal="true" aria-labelledby="contact-profile-name">
            <header class="contact-profile-header">
                <flux:button wire:click="closeContactProfile" variant="ghost" icon="x-mark" square aria-label="Close profile" />
                <span>Contact info</span>
                <span class="profile-header-spacer"></span>
            </header>
            <div class="contact-profile-content">
                <div class="contact-profile-identity">
                    <flux:avatar initials="{{ $this->activeConversation['initials'] }}" color="zinc" size="xl" />
                    <h2 id="contact-profile-name">{{ $this->activeConversation['name'] }}</h2>
                    <p>{{ $this->activeConversation['status'] }}</p>
                    <div class="profile-quick-actions">
                        <button type="button" wire:click="callActiveConversation" class="profile-quick-action">
                            <flux:icon.phone /><span>Call</span>
                        </button>
                        <button type="button" class="profile-quick-action"><flux:icon.magnifying-glass /><span>Search</span></button>
                    </div>
                </div>

                <section class="profile-settings-group" aria-labelledby="profile-chat-settings">
                    <h3 id="profile-chat-settings">Chat settings</h3>
                    <label class="profile-setting-row" for="disappearing-messages">
                        <span class="profile-setting-icon">
                            <flux:icon.clock />
                        </span>
                        <span class="profile-setting-copy"><strong>Disappearing messages</strong><small>New messages on this device</small></span>
                        <select id="disappearing-messages" class="profile-setting-select" wire:change="setDisappearingMessages($event.target.value)">
                            <option value="off" @selected($this->activeConversationPreferences['disappearing'] === 'off')>Off</option>
                            <option value="24h" @selected($this->activeConversationPreferences['disappearing'] === '24h')>24 hours</option>
                            <option value="7d" @selected($this->activeConversationPreferences['disappearing'] === '7d')>7 days</option>
                            <option value="90d" @selected($this->activeConversationPreferences['disappearing'] === '90d')>90 days</option>
                        </select>
                    </label>
                </section>

                <section class="profile-settings-group" aria-labelledby="profile-privacy">
                    <h3 id="profile-privacy">Privacy & security</h3>
                    <div class="profile-info-row"><span class="profile-setting-icon"><flux:icon.lock-closed /></span><span class="profile-setting-copy"><strong>Encryption</strong><small>Standard SMS is not end-to-end encrypted</small></span>
                        <flux:badge color="amber">SMS</flux:badge>
                    </div>
                    <div class="profile-info-row"><span class="profile-setting-icon"><flux:icon.device-phone-mobile /></span><span class="profile-setting-copy"><strong>Message privacy</strong><small>Clear chat removes messages from this device only</small></span></div>
                </section>

                <section class="profile-settings-group profile-danger-group" aria-label="Contact actions">
                    <button type="button" wire:click="clearChat" wire:confirm="Clear all messages in this chat from this device?" class="profile-action-row">
                        <flux:icon.trash /><span>Clear chat</span>
                    </button>
                    <button type="button" wire:click="toggleBlockContact" class="profile-action-row {{ $this->activeConversationPreferences['blocked'] ? '' : 'is-danger' }}"><flux:icon.no-symbol /><span>{{ $this->activeConversationPreferences['blocked'] ? 'Unblock contact' : 'Block contact' }}</span></button>
                    <button type="button" wire:click="reportContact" wire:confirm="Mark this contact as reported?" class="profile-action-row is-danger" @disabled($this->activeConversationPreferences['reported'])>
                        <flux:icon.flag /><span>{{ $this->activeConversationPreferences['reported'] ? 'Contact reported' : 'Report contact' }}</span>
                    </button>
                </section>
            </div>
        </aside>
        @endif
    </main>

    @include('livewire.status-creator')

    @if($showSettings)
    <section class="settings-drawer {{ $activeSetting === 'storage' ? 'is-storage-setting' : '' }}" aria-label="AirText settings">
        <header class="settings-drawer-header">
            <flux:button wire:click="{{ $activeSetting === 'storage' ? 'backFromStorageSettings' : 'closeSettings' }}" variant="ghost" icon="arrow-left" square aria-label="{{ $activeSetting === 'storage' ? (($showStorageDetails || $showNetworkDetails || $showProxyDetails) ? 'Back to storage and data' : 'Back to settings') : 'Back to chats' }}" />
            <div>
                <flux:heading size="lg">{{ $activeSetting !== 'storage' ? 'Settings' : ($showStorageDetails ? 'Manage storage' : ($showNetworkDetails ? 'Network usage' : ($showProxyDetails ? 'Proxy' : 'Storage and data'))) }}</flux:heading>
                @if($activeSetting !== 'storage')<flux:text size="sm">AirText workspace preferences</flux:text>@endif
            </div>
        </header>

        <div class="settings-drawer-body">
            <nav class="settings-navigation {{ $activeSetting === 'storage' ? 'is-storage-setting' : '' }}" aria-label="Settings sections">
                @foreach([
                'profile' => ['icon' => 'user-circle', 'label' => 'Profile & SMS Identity'],
                'payload' => ['icon' => 'chat-bubble-left-right', 'label' => 'Chats & Payload Preferences'],
                'gateway' => ['icon' => 'signal', 'label' => 'SMS Gateway & Transport Configuration'],
                'notifications' => ['icon' => 'bell', 'label' => 'Notifications & Delivery Alerts'],
                'privacy' => ['icon' => 'lock-closed', 'label' => 'Privacy & Blocked Contacts'],
                'storage' => ['icon' => 'circle-stack', 'label' => 'Storage and data'],
                ] as $key => $section)
                <button wire:click="selectSetting('{{ $key }}')" class="settings-nav-item {{ $activeSetting === $key ? 'is-active' : '' }}">
                    <flux:icon name="{{ $section['icon'] }}" variant="outline" class="settings-nav-icon" />
                    <span>{{ $section['label'] }}</span>
                    <flux:icon.chevron-right class="settings-nav-arrow" />
                </button>
                @endforeach
            </nav>

            <div class="settings-content {{ $activeSetting === 'storage' ? 'is-storage-setting' : '' }}">
                @if($activeSetting === 'profile')
                <div class="settings-section-heading">
                    <flux:heading size="xl">Profile & SMS Identity</flux:heading>
                    <flux:subheading>How your identity appears when you send a normal SMS.</flux:subheading>
                </div>
                <div class="settings-profile-card">
                    @if($profilePhotoUrl)
                    <img src="{{ $profilePhotoUrl }}" alt="{{ $displayName }}" class="settings-profile-avatar" />
                    @else
                    <flux:avatar initials="A" color="green" size="lg" />
                    @endif
                    <div>
                        <flux:heading size="lg">{{ $displayName }}</flux:heading>
                        <flux:text>{{ $phoneNumber }}</flux:text>
                    </div>
                    <flux:badge color="blue">Verified</flux:badge>
                </div>
                <flux:field>
                    <flux:label>Profile photo</flux:label>
                    <input type="file" accept="image/png,image/jpeg,image/webp" wire:model="profilePhoto" class="settings-file-input" />
                    @error('profilePhoto')<flux:error>{{ $message }}</flux:error>@enderror
                </flux:field>
                @if($profilePhotoUrl)
                <flux:button type="button" wire:click="removeProfilePhoto" variant="ghost" icon="trash">Remove photo</flux:button>
                @endif
                <flux:button type="button" wire:click="uploadProfilePhoto" variant="primary" icon="check">Upload photo</flux:button>
                <flux:field>
                    <flux:label>Display name</flux:label>
                    <flux:input wire:model="displayName" />
                </flux:field>
                <flux:field>
                    <flux:label>SMS identity number</flux:label>
                    <flux:input wire:model="phoneNumber" />
                </flux:field>
                <flux:button variant="primary" icon="check">Save identity</flux:button>
                @elseif($activeSetting === 'payload')
                <div class="settings-section-heading">
                    <flux:heading size="xl">Chats & Payload Preferences</flux:heading>
                    <flux:subheading>Control how AirText formats messages before they leave your phone.</flux:subheading>
                </div>
                <flux:field>
                    <flux:label>Default payload prefix</flux:label><select wire:model="payloadPrefix" class="settings-select">
                        <option>MSG:</option>
                        <option>STAT:</option>
                        <option>ACK:</option>
                    </select>
                </flux:field>
                <flux:checkbox label="Show delivery status in every conversation" checked />
                <flux:checkbox label="Keep message previews in the chat list" checked />
                <div class="settings-info-card"><flux:icon.information-circle variant="outline" /><span>AirText uses normal SMS transport. Payload prefixes help the receiver distinguish messages, statuses, and receipts.</span></div>
                @elseif($activeSetting === 'gateway')
                <div class="settings-section-heading">
                    <flux:heading size="xl">SMS Gateway & Transport</flux:heading>
                    <flux:subheading>Choose the carrier integration that sends and receives your SMS traffic.</flux:subheading>
                </div>
                <div class="gateway-status"><span class="gateway-status-dot"></span>
                    <div><strong>Gateway connected</strong>
                        <flux:text size="sm">Ready to send through your configured transport.</flux:text>
                    </div>
                </div>
                <flux:field>
                    <flux:label>Transport driver</flux:label><select wire:model="gatewayDriver" class="settings-select">
                        <option>Africa's Talking</option>
                        <option>Twilio</option>
                        <option>Local GSM modem</option>
                    </select>
                </flux:field>
                <flux:field>
                    <flux:label>Sender number</flux:label>
                    <flux:input value="+255XXXXXXXXX" readonly />
                </flux:field>
                <flux:button variant="primary" icon="signal">Test gateway</flux:button>
                @elseif($activeSetting === 'notifications')
                <div class="settings-section-heading">
                    <flux:heading size="xl">Notifications & Delivery Alerts</flux:heading>
                    <flux:subheading>Choose which SMS events should interrupt your workflow.</flux:subheading>
                </div>
                <flux:checkbox wire:model="deliveryAlerts" label="Delivery and read receipts" />
                <flux:checkbox wire:model="lowBalanceAlerts" label="Low gateway balance alerts" />
                <flux:checkbox label="Failed message alerts" checked />
                @elseif($activeSetting === 'privacy')
                <div class="settings-section-heading">
                    <flux:heading size="xl">Privacy & Blocked Contacts</flux:heading>
                    <flux:subheading>Keep your SMS identity and conversations under your control.</flux:subheading>
                </div>
                <flux:field>
                    <flux:label>Last seen</flux:label>
                    <select wire:model="lastSeenVisibility" class="settings-select">
                        <option>Everyone</option>
                        <option>My contacts</option>
                        <option>My contacts except...</option>
                        <option>Nobody</option>
                    </select>
                </flux:field>
                <flux:field>
                    <flux:label>Profile photo</flux:label>
                    <select wire:model="profilePictureVisibility" class="settings-select">
                        <option>Everyone</option>
                        <option>My contacts</option>
                        <option>Nobody</option>
                    </select>
                </flux:field>
                <flux:field>
                    <flux:label>Status visibility</flux:label>
                    <select wire:model="statusVisibility" class="settings-select">
                        <option>Everyone</option>
                        <option>My contacts</option>
                        <option>Nobody</option>
                    </select>
                </flux:field>
                <flux:checkbox label="Hide message content in desktop notifications" checked />
                <flux:checkbox label="Require confirmation before sending to a new number" checked />
                <div class="settings-info-card"><flux:icon.lock-closed variant="outline" /><span>No internet account is required. Your privacy settings apply to this device and its normal SMS workflow.</span></div>
                <flux:button type="button" wire:click="savePrivacySettings" variant="primary" icon="check">Save privacy</flux:button>
                <flux:button variant="danger" icon="no-symbol">Manage blocked contacts</flux:button>
                @else
                <div class="storage-page">
                    @if(! $showStorageDetails && ! $showNetworkDetails && ! $showProxyDetails)
                    <div class="storage-setting-list">
                        <button type="button" class="storage-setting-row storage-setting-link" wire:click="openStorageDetails">
                            <flux:icon.folder variant="outline" />
                            <span class="storage-setting-copy"><strong>Manage storage</strong><small>{{ number_format($this->storageSummary['message_count']) }} messages · {{ $this->formatStorageBytes($this->storageSummary['storage_bytes']) }} voice media</small></span>
                            <flux:icon.chevron-right variant="outline" />
                        </button>
                        <button type="button" class="storage-setting-row storage-setting-link" wire:click="openNetworkDetails">
                            <flux:icon.chart-bar variant="outline" />
                            <span class="storage-setting-copy"><strong>Network usage</strong><small>View AirText data sent and received this month.</small></span>
                            <flux:icon.chevron-right variant="outline" />
                        </button>
                        <label class="storage-setting-row storage-switch-row" for="use-less-data-calls">
                            <flux:icon.phone variant="outline" />
                            <span class="storage-setting-copy"><strong>Use less data for calls</strong><small>Preference saved to your AirText account</small></span>
                            <input id="use-less-data-calls" type="checkbox" class="storage-switch" wire:model="useLessDataForCalls" wire:change="saveStorageSettings" />
                        </label>
                        <button type="button" class="storage-setting-row storage-setting-link" wire:click="openProxyDetails">
                            <flux:icon.shield-exclamation variant="outline" />
                            <span class="storage-setting-copy"><strong>Proxy</strong><small>View browser proxy status and connection.</small></span>
                            <flux:icon.chevron-right variant="outline" />
                        </button>
                    </div>

                    <div class="storage-setting-list">
                        <label class="storage-setting-row" for="media-upload-quality">
                            <flux:icon.photo variant="outline" />
                            <span class="storage-setting-copy"><strong>Media upload quality</strong><small>Choose the default quality</small></span>
                            <select id="media-upload-quality" class="storage-setting-select" wire:model="uploadQuality" wire:change="saveStorageSettings">
                                <option value="hd">HD quality</option>
                                <option value="standard">Standard quality</option>
                            </select>
                        </label>
                        <label class="storage-setting-row" for="auto-download-quality">
                            <span class="storage-setting-icon-spacer"></span>
                            <span class="storage-setting-copy"><strong>Auto-download quality</strong><small>Choose the default quality</small></span>
                            <select id="auto-download-quality" class="storage-setting-select" wire:model="autoDownloadQuality" wire:change="saveStorageSettings">
                                <option value="auto">Auto</option>
                                <option value="high">High quality</option>
                            </select>
                        </label>
                    </div>

                    <section class="storage-auto-download" aria-labelledby="storage-download-heading">
                        <h2 id="storage-download-heading">Media auto-download</h2>
                        <p class="storage-setting-note">Voice messages are downloaded when you play them in this web app.</p>
                        <label class="storage-setting-row" for="mobile-data-downloads">
                            <span class="storage-setting-icon-spacer"></span>
                            <span class="storage-setting-copy"><strong>When using mobile data</strong></span>
                            <select id="mobile-data-downloads" class="storage-setting-select" wire:model="mobileDataDownloads" wire:change="saveStorageSettings">
                                <option value="none">No media</option>
                                <option value="photos">Photos</option>
                                <option value="all">All media</option>
                            </select>
                        </label>
                        <label class="storage-setting-row" for="wifi-downloads">
                            <span class="storage-setting-icon-spacer"></span>
                            <span class="storage-setting-copy"><strong>When connected on Wi-Fi</strong></span>
                            <select id="wifi-downloads" class="storage-setting-select" wire:model="wifiDownloads" wire:change="saveStorageSettings">
                                <option value="none">No media</option>
                                <option value="photos">Photos</option>
                                <option value="all">All media</option>
                            </select>
                        </label>
                        <label class="storage-setting-row" for="roaming-downloads">
                            <span class="storage-setting-icon-spacer"></span>
                            <span class="storage-setting-copy"><strong>When roaming</strong></span>
                            <select id="roaming-downloads" class="storage-setting-select" wire:model="roamingDownloads" wire:change="saveStorageSettings">
                                <option value="none">No media</option>
                                <option value="photos">Photos</option>
                                <option value="all">All media</option>
                            </select>
                        </label>
                    </section>

                    <section class="storage-auto-download" aria-labelledby="storage-display-heading">
                        <h2 id="storage-display-heading">Media display</h2>
                        <div class="storage-setting-row storage-device-row" data-device-display aria-live="polite">
                            <flux:icon.device-phone-mobile variant="outline" />
                            <span class="storage-setting-copy">
                                <strong data-device-name>Detecting this device...</strong>
                                <small><span data-device-os>Reading operating system</span> · <span data-device-browser>Reading browser</span></small>
                                <small data-device-note>Device details are detected locally by this browser.</small>
                            </span>
                        </div>
                    </section>
                    @elseif($showNetworkDetails)
                    <section class="storage-detail-page" aria-labelledby="network-usage-heading">
                        <div class="storage-detail-intro">
                            <flux:icon.chart-bar variant="outline" />
                            <div>
                                <h2 id="network-usage-heading">Network usage</h2>
                                <p>AirText app traffic · {{ $this->networkUsageSummary['period_label'] }}</p>
                            </div>
                        </div>
                        <div class="network-usage-stats">
                            <div><span>Sent</span><strong>{{ $this->formatStorageBytes($this->networkUsageSummary['uploaded_bytes']) }}</strong></div>
                            <div><span>Received</span><strong>{{ $this->formatStorageBytes($this->networkUsageSummary['downloaded_bytes']) }}</strong></div>
                            <div><span>Requests</span><strong>{{ number_format($this->networkUsageSummary['request_count']) }}</strong></div>
                        </div>
                        <p class="storage-safety-note">Counts API and signed-in web request payloads recorded by AirText. They do not include mobile carrier overhead, other apps, browser assets served outside Laravel, or device background traffic.</p>
                    </section>
                    @elseif($showProxyDetails)
                    <section class="storage-detail-page" aria-labelledby="proxy-heading" x-data="{ status: 'Not checked', async check() { this.status = 'Checking connection...'; try { const response = await fetch('/up', { cache: 'no-store' }); this.status = response.ok ? 'AirText is reachable through this browser connection.' : 'AirText returned a connection error.'; } catch (error) { this.status = 'AirText could not be reached through this browser connection.'; } } }">
                        <div class="storage-detail-intro">
                            <flux:icon.shield-check variant="outline" />
                            <div>
                                <h2 id="proxy-heading">Proxy</h2>
                                <p>Browser network settings</p>
                            </div>
                        </div>
                        <div class="proxy-settings-note">
                            <strong>Proxy is controlled by your browser or device.</strong>
                            <p>A website cannot change your device-wide proxy or route other apps through one. Configure a proxy in your operating system or browser; AirText will use the browser's existing network route.</p>
                        </div>
                        <button type="button" class="proxy-check-button" x-on:click="check()">Check connection</button>
                        <p class="proxy-check-status" role="status" x-text="status">Not checked</p>
                    </section>
                    @elseif($showStorageDetails)
                    <section id="manage-storage" class="storage-management-section" aria-labelledby="storage-sms-heading">
                        <div class="storage-management-header">
                            <div>
                                <h2 id="storage-sms-heading">Manage storage</h2>
                                <p>{{ number_format($this->storageSummary['conversation_count']) }} conversations · {{ number_format($this->storageSummary['message_count']) }} messages</p>
                            </div>
                            <flux:button type="button" wire:click="clearAllStoredSmsMessages" wire:confirm="Permanently delete all messages in your SMS conversations? This cannot be undone." variant="danger" icon="trash" :disabled="$this->storageSummary['sms_message_count'] === 0">
                                Clear all SMS messages
                            </flux:button>
                        </div>
                        <div class="storage-conversation-list">
                            @forelse($this->storedSmsConversations as $storedConversation)
                            <div class="storage-conversation-row">
                                <div>
                                    <strong>{{ $storedConversation['name'] }}</strong>
                                    <small>{{ number_format($storedConversation['message_count']) }} messages</small>
                                </div>
                                <flux:button type="button" wire:click="clearStoredSmsConversation({{ $storedConversation['id'] }})" wire:confirm="Permanently delete all messages in this SMS conversation? This cannot be undone." variant="ghost" icon="trash" :disabled="$storedConversation['message_count'] === 0" aria-label="Clear messages for {{ $storedConversation['name'] }}" />
                            </div>
                            @empty
                            <p class="storage-empty-state">No SMS conversations are stored for this account.</p>
                            @endforelse
                        </div>
                        <p class="storage-safety-note">Shared AirText conversations are excluded so clearing storage does not delete messages for another participant.</p>
                    </section>
                    @endif
                </div>
                @endif
            </div>
        </div>
    </section>
    @endif
</div>
