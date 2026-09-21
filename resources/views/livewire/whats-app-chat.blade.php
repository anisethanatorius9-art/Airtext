<div class="whatsapp-app">
    <aside class="whatsapp-rail">
        <div class="rail-top">
            <flux:button wire:click="showPanel('chats')" variant="ghost" icon="chat-bubble-left-right" square aria-label="Chats" />
            <flux:button wire:click="showPanel('calls')" variant="ghost" icon="phone" square aria-label="Calls" />
            <flux:button wire:click="showPanel('status')" variant="ghost" icon="globe-alt" square aria-label="Status updates" />
            <flux:button wire:click="showPanel('channels')" variant="ghost" icon="megaphone" square aria-label="Channels" />
            <flux:button wire:click="showPanel('contacts')" variant="ghost" icon="users" square aria-label="Contacts" />
            <flux:button variant="ghost" icon="user-group" square aria-label="Communities and groups" />
        </div>
        <div class="rail-separator" aria-hidden="true"></div>
        <div class="rail-services">
            <flux:button wire:click="showPanel('shop')" variant="ghost" icon="building-storefront" square aria-label="AirText Shop and SMS services" />
            <flux:button variant="ghost" icon="bell-alert" square aria-label="AirText announcements" />
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
                <div class="shop-context-links"><span class="is-active"><flux:icon.squares-2x2 variant="outline" /> Browse services</span><span><flux:icon.shopping-bag variant="outline" /> Installed items</span><span><flux:icon.wallet variant="outline" /> Wallet & billing</span></div>
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
                        <a href="tel:{{ str_replace(' ', '', $call['number']) }}" class="quick-call" aria-label="Call {{ $call['name'] }}">
                            <flux:icon.phone />
                        </a>
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
            <flux:heading size="xl">Channels</flux:heading>
            <flux:button variant="ghost" icon="plus" square aria-label="Create channel" />
        </header>
        <div class="panel-search">
            <flux:input wire:model.live="search" icon="magnifying-glass" placeholder="Discover channels" />
        </div>
        <button class="add-contact-row">
            <flux:icon.megaphone variant="outline" /><span><strong>Create a channel</strong><small>Broadcast updates by SMS</small></span><flux:icon.chevron-right />
        </button>
        <nav class="chat-list" aria-label="Subscribed channels">
            @foreach($channels as $channel)
            <button class="chat-list-item">
                <flux:avatar initials="{{ $channel['initials'] }}" color="zinc" size="md" /><span class="chat-list-copy"><strong>{{ $channel['name'] }}</strong><span>{{ $channel['announcement'] }}</span></span>
            </button>
            @endforeach
        </nav>
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
        @if($showWebContactNotice)
        <div class="contact-notice-backdrop">
            <section class="contact-notice-modal" role="dialog" aria-modal="true" aria-labelledby="contact-notice-title">
                <div class="contact-notice-icon"><flux:icon.book-open variant="outline" /></div>
                <flux:heading id="contact-notice-title" size="lg">Manage contacts from web</flux:heading>
                <flux:text>On your phone, turn on AirText contacts to start managing contacts from web. Go to AirText &gt; Settings &gt; Privacy &gt; Contacts. Learn more.</flux:text>
                <div class="contact-notice-actions">
                    <flux:button wire:click="closeWebContactNotice" variant="ghost">Cancel</flux:button>
                    <flux:button wire:click="closeWebContactNotice" variant="primary">OK</flux:button>
                </div>
            </section>
        </div>
        @endif
    </aside>

    <main class="whatsapp-conversation">
        @if($leftPanel === 'shop')
            @include('livewire.shop-content')
        @elseif($leftPanel === 'status')
            @include('livewire.status-viewer')
        @else
        <header class="conversation-header">
            <div class="conversation-contact">
                <flux:avatar initials="{{ $this->activeConversation['initials'] }}" color="zinc" size="sm" />
                <div><strong>{{ $this->activeConversation['name'] }}</strong><span>{{ $this->activeConversation['status'] }}</span></div>
            </div>
            <div class="header-actions">
                <flux:button variant="ghost" icon="video-camera" square aria-label="Video call" />
                <flux:button variant="ghost" icon="magnifying-glass" square aria-label="Search conversation" />
                <flux:dropdown position="bottom" align="end">
                    <flux:button variant="ghost" icon="ellipsis-vertical" square aria-label="Conversation menu" />
                    <flux:menu>
                        <flux:menu.item icon="information-circle">Contact info</flux:menu.item>
                        <flux:menu.item icon="archive-box">Archive chat</flux:menu.item>
                    </flux:menu>
                </flux:dropdown>
            </div>
        </header>

        <section class="messages-area" aria-label="Messages">
            <div class="message-date">Today</div>
            @foreach($this->activeConversation['messages'] as $message)
            <div wire:key="message-{{ $loop->index }}" class="message-line {{ $message['mine'] ? 'is-outgoing' : 'is-incoming' }}">
                <article class="whatsapp-message">
                    @if(!empty($message['code']))
                    <pre class="code-message"><code>{{ $message['body'] }}</code></pre>
                    @elseif(!empty($message['attachment']))
                    <div class="document-message"><span class="document-icon">▤</span><span><strong>{{ $message['body'] }}</strong><small>1 DOCX · 24 KB</small></span></div>
                    @else
                    <p>{{ $message['body'] }}</p>
                    @endif
                    <small class="message-meta">{{ $message['time'] }} @if($message['mine'])<span class="message-checks">✓✓</span>@endif</small>
                </article>
            </div>
            @endforeach
            <p class="sms-note">Messages are sent over normal SMS. No Wi-Fi or mobile data required.</p>
        </section>

        <form wire:submit="sendMessage" class="message-composer">
            <flux:button type="button" variant="ghost" icon="face-smile" square aria-label="Add emoji" />
            <flux:button type="button" variant="ghost" icon="paper-clip" square aria-label="Attach file" />
            <flux:input wire:model="messageDraft" class="composer-input" placeholder="Type a message" aria-label="Type a message" />
            <flux:button type="submit" variant="primary" icon="paper-airplane" square aria-label="Send message" />
        </form>
        @endif
    </main>

    @include('livewire.status-creator')

    @if($showSettings)
    <section class="settings-drawer" aria-label="AirText settings">
        <header class="settings-drawer-header">
            <flux:button wire:click="closeSettings" variant="ghost" icon="arrow-left" square aria-label="Back to chats" />
            <div>
                <flux:heading size="lg">Settings</flux:heading>
                <flux:text size="sm">AirText workspace preferences</flux:text>
            </div>
        </header>

        <div class="settings-drawer-body">
            <nav class="settings-navigation" aria-label="Settings sections">
                @foreach([
                'profile' => ['icon' => 'user-circle', 'label' => 'Profile & SMS Identity'],
                'payload' => ['icon' => 'chat-bubble-left-right', 'label' => 'Chats & Payload Preferences'],
                'gateway' => ['icon' => 'signal', 'label' => 'SMS Gateway & Transport Configuration'],
                'notifications' => ['icon' => 'bell', 'label' => 'Notifications & Delivery Alerts'],
                'privacy' => ['icon' => 'lock-closed', 'label' => 'Privacy & Blocked Contacts'],
                'storage' => ['icon' => 'circle-stack', 'label' => 'SMS Data, Queue & Storage Management'],
                ] as $key => $section)
                <button wire:click="selectSetting('{{ $key }}')" class="settings-nav-item {{ $activeSetting === $key ? 'is-active' : '' }}">
                    <flux:icon name="{{ $section['icon'] }}" variant="outline" class="settings-nav-icon" />
                    <span>{{ $section['label'] }}</span>
                    <flux:icon.chevron-right class="settings-nav-arrow" />
                </button>
                @endforeach
            </nav>

            <div class="settings-content">
                @if($activeSetting === 'profile')
                <div class="settings-section-heading">
                    <flux:heading size="xl">Profile & SMS Identity</flux:heading>
                    <flux:subheading>How your identity appears when you send a normal SMS.</flux:subheading>
                </div>
                <div class="settings-profile-card">
                    <flux:avatar initials="A" color="green" size="lg" />
                    <div>
                        <flux:heading size="lg">{{ $displayName }}</flux:heading>
                        <flux:text>{{ $phoneNumber }}</flux:text>
                    </div>
                    <flux:badge color="blue">Verified</flux:badge>
                </div>
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
                <flux:checkbox label="Hide message content in desktop notifications" checked />
                <flux:checkbox label="Require confirmation before sending to a new number" checked />
                <div class="settings-info-card"><flux:icon.lock-closed variant="outline" /><span>No internet account is required. Your privacy settings apply to this device and its normal SMS workflow.</span></div>
                <flux:button variant="danger" icon="no-symbol">Manage blocked contacts</flux:button>
                @else
                <div class="settings-section-heading">
                    <flux:heading size="xl">SMS Data, Queue & Storage</flux:heading>
                    <flux:subheading>Review local queue health and manage stored conversation data.</flux:subheading>
                </div>
                <div class="storage-grid">
                    <div><strong>0</strong><span>Queued messages</span></div>
                    <div><strong>3</strong><span>Conversations</span></div>
                    <div><strong>24 KB</strong><span>Local attachments</span></div>
                </div>
                <flux:button variant="outline" icon="arrow-path">Retry queued messages</flux:button>
                <flux:button variant="danger" icon="trash">Clear local message cache</flux:button>
                @endif
            </div>
        </div>
    </section>
    @endif
</div>
