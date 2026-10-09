<?php

namespace App\Livewire;

use App\Models\Contact;
use App\Models\Conversation;
use App\Models\Status;
use Flux\Flux;
use Illuminate\View\View;
use Livewire\Attributes\Layout;
use Livewire\Component;
use Livewire\WithFileUploads;

/**
 * @phpstan-type ShopProduct array{id: string, category: string, icon: string, eyebrow: string, name: string, description: string, price: int, price_label: string, action: string}
 * @phpstan-type ContactRow array{id: int, name: string, phone_number: string, initials: string, status: mixed, is_registered: bool}
 * @phpstan-type CallRow array{name: string, number: string, initials: string, direction: string, time: string, duration: string, missed: bool}
 * @phpstan-type ChatMessageRow array{body: string, time: string, mine: bool, expires_at?: string, code?: bool, attachment?: bool}
 * @phpstan-type ConversationRow array{id: int, name: string, initials: string, tone: string, time: string, preview: string, status: string, unread: int, messages: array<int, ChatMessageRow>}
 *
 * @property-read array<string, mixed> $activeConversation
 * @property-read array<string, bool|string> $activeConversationPreferences
 * @property-read array<int, ContactRow> $filteredContacts
 * @property-read array<int, CallRow> $filteredCalls
 * @property-read array<int, ShopProduct> $filteredShopProducts
 * @property-read array<int, ContactRow> $registeredContacts
 * @property-read array<int, array{name: string, phone_number: string, initials: string}> $inviteContacts
 * @property-read array<int, array<string, mixed>> $statusUpdates
 * @property-read array<int, array<string, mixed>> $recentStatuses
 * @property-read array<int, array<string, mixed>> $viewedStatuses
 * @property-read array<string, mixed>|null $activeStatus
 */
#[Layout('components.layouts.whatsapp')]
class WhatsAppChat extends Component
{
    use WithFileUploads;

    public string $search = '';

    public string $filter = 'All';

    public string $messageDraft = '';

    public int $activeConversationId = 1;

    public bool $showConversation = false;

    public bool $showEmojiPicker = false;

    public bool $showSettings = false;

    public bool $showContactProfile = false;

    /** @var array<int, array<string, bool|string>> */
    public array $conversationPreferences = [];

    public string $activeSetting = 'profile';

    public string $displayName = '@amjunior89';

    public string $phoneNumber = '+255 712 884 102';

    public string $payloadPrefix = 'MSG:';

    public string $gatewayDriver = 'Africa\'s Talking';

    public bool $deliveryAlerts = true;

    public bool $lowBalanceAlerts = true;

    public string $leftPanel = 'chats';

    public string $shopSearch = '';

    public string $shopCategory = 'all';

    /** @var array<int, ShopProduct> */
    public array $shopProducts = [
        ['id' => 'credits-5000', 'category' => 'credits', 'icon' => 'cube', 'eyebrow' => '5,000 BULK SMS', 'name' => 'SMS Credits Package', 'description' => 'High-throughput local GSM routes for campaigns and alerts.', 'price' => 50000, 'price_label' => 'TZS 50,000', 'action' => 'Buy package'],
        ['id' => 'gemini-bot', 'category' => 'bots', 'icon' => 'cpu-chip', 'eyebrow' => 'GEMINI AI BOT', 'name' => 'AI Auto-Responder Bot', 'description' => 'Automated SMS customer support that replies around the clock.', 'price' => 15000, 'price_label' => 'TZS 15,000 / month', 'action' => 'Install bot'],
        ['id' => 'sender-id', 'category' => 'gateways', 'icon' => 'tag', 'eyebrow' => 'BRANDED SENDER ID', 'name' => 'Custom Sender ID', 'description' => 'Register a trusted business name for your outgoing messages.', 'price' => 30000, 'price_label' => 'TZS 30,000 / year', 'action' => 'Request ID'],
        ['id' => 'tourism-bot', 'category' => 'bots', 'icon' => 'sparkles', 'eyebrow' => 'READY TO DEPLOY', 'name' => 'Tourism Concierge Bot', 'description' => 'Answer booking and itinerary questions automatically.', 'price' => 12000, 'price_label' => 'TZS 12,000 / month', 'action' => 'Install bot'],
        ['id' => 'order-template', 'category' => 'templates', 'icon' => 'document-text', 'eyebrow' => 'MESSAGE TEMPLATE', 'name' => 'Order Updates Pack', 'description' => 'Prebuilt delivery, payment, and order notification flows.', 'price' => 8000, 'price_label' => 'TZS 8,000 one-time', 'action' => 'Get template'],
        ['id' => 'gsm-node', 'category' => 'gateways', 'icon' => 'signal', 'eyebrow' => '99.9% UPTIME', 'name' => 'Dedicated GSM Gateway Node', 'description' => 'A dedicated route for reliable business-critical SMS traffic.', 'price' => 45000, 'price_label' => 'TZS 45,000 / month', 'action' => 'Activate node'],
    ];

    /** @var array<int, array<string, string>> */
    public array $installedShopItems = [
    ];

    public bool $showContactForm = false;

    public bool $showWebContactNotice = false;

    public bool $showFavoritePicker = false;

    public bool $showDialpad = false;

    public string $dialNumber = '';

    public bool $showCallScreen = false;

    public string $callName = '';

    public string $callNumber = '';

    public bool $callSpeaker = false;

    public bool $callMuted = false;

    public bool $callVideo = false;

    public bool $callMoreOpen = false;

    /** @var array<int, array<string, mixed>> */
    public array $favorites = [];

    public bool $showStatusCreator = false;

    public ?int $activeStatusId = null;

    public int $activeStatusIndex = 0;

    public bool $statusPaused = false;

    public bool $statusMuted = false;

    public string $statusMode = 'text';

    public string $statusText = '';

    public string $statusCaption = '';

    public string $statusReply = '';

    public string $statusPrivacy = 'Contacts';

    public string $statusBackground = '#00a884';

    public string $statusFont = 'sans';

    public mixed $statusMedia = null;

    public string $contactFirstName = '';

    public string $contactLastName = '';

    public string $contactPhone = '';

    public string $contactPayloadPrefix = 'MSG:';

    /** @var array<int, array{name: string, phone_number: string, initials: string}> */
    public array $deviceContacts = [
        ['name' => 'Neema Studio', 'phone_number' => '+255 763 100 445', 'initials' => 'NS'],
        ['name' => 'Mariam Hassan', 'phone_number' => '+255 718 220 901', 'initials' => 'MH'],
    ];

    /** @var array<int, array{name: string, number: string, initials: string, direction: string, time: string, duration: string, missed: bool}> */
    public array $calls = [
        ['name' => 'Juma K.', 'number' => '+255 712 884 102', 'initials' => 'JK', 'direction' => 'outbound', 'time' => 'Today, 10:14 AM', 'duration' => '04:32', 'missed' => false],
        ['name' => 'Unknown number', 'number' => '+255 782 328 215', 'initials' => '+255', 'direction' => 'inbound', 'time' => 'Today, 8:42 AM', 'duration' => '01:08', 'missed' => false],
        ['name' => 'Lina A.', 'number' => '+255 754 991 204', 'initials' => 'LA', 'direction' => 'inbound', 'time' => 'Yesterday, 6:20 PM', 'duration' => '', 'missed' => true],
    ];

    /** @var array<int, array{name: string, initials: string, announcement: string}> */
    public array $channels = [
        ['name' => 'AirText updates', 'initials' => '✦', 'announcement' => 'Payload protocol updates and service news'],
        ['name' => 'Dar Studio Network', 'initials' => 'DS', 'announcement' => 'New studio announcements this week'],
    ];

    /** @var array<int, ConversationRow> */
    public array $conversations = [
        [
            'id' => 1,
            'name' => '@amjunior89 (You)',
            'initials' => 'AJ',
            'tone' => 'bg-slate-500',
            'time' => '9:55 AM',
            'preview' => 'AirText: Offline SMS conversation active...',
            'status' => 'Business Account',
            'unread' => 0,
            'messages' => [
                ['body' => 'Can you give me the payload code for AirText SMS parsing?', 'time' => '10:41 AM', 'mine' => false],
                ['body' => 'class SmsPayloadService { return "MSG:{$content}"; }', 'time' => '10:42 AM', 'mine' => true, 'code' => true],
                ['body' => 'AirText_SDLC_Documentation.docx', 'time' => '10:45 AM', 'mine' => true, 'attachment' => true],
            ],
        ],
        [
            'id' => 2,
            'name' => '+255 782 328 215',
            'initials' => '+255',
            'tone' => 'bg-emerald-500',
            'time' => '5:51 AM',
            'preview' => 'Ni vizuri sana mimi ni yale software...',
            'status' => 'SMS contact',
            'unread' => 2,
            'messages' => [
                ['body' => 'Ni vizuri sana mimi ni yale software...', 'time' => '5:51 AM', 'mine' => false],
            ],
        ],
        [
            'id' => 3,
            'name' => 'Juma K.',
            'initials' => 'JK',
            'tone' => 'bg-orange-400',
            'time' => 'Yesterday',
            'preview' => 'The studio address is on its way.',
            'status' => 'Active now',
            'unread' => 0,
            'messages' => [
                ['body' => 'The studio address is on its way.', 'time' => 'Yesterday', 'mine' => false],
            ],
        ],
    ];

    /** @return ConversationRow */
    public function getActiveConversationProperty(): array
    {
        $conversation = collect($this->conversations)->firstWhere('id', $this->activeConversationId) ?? $this->conversations[0];
        $conversation['messages'] = collect($conversation['messages'])
            ->reject(fn (array $message): bool => isset($message['expires_at']) && now()->greaterThanOrEqualTo($message['expires_at']))
            ->values()
            ->all();

        return $conversation;
    }

    /** @return array<int, ConversationRow> */
    public function getFilteredConversationsProperty(): array
    {
        return collect($this->conversations)
            ->filter(fn (array $conversation): bool => $this->filter === 'All' || ($this->filter === 'Unread' && $conversation['unread'] > 0))
            ->filter(fn (array $conversation): bool => $this->search === '' || str_contains(strtolower($conversation['name']), strtolower($this->search)))
            ->values()
            ->all();
    }

    /** @return array<int, array<string, int|string>> */
    /** @return array<int, ShopProduct> */
    public function getFilteredShopProductsProperty(): array
    {
        return collect($this->shopProducts)
            ->filter(fn (array $product): bool => $this->shopCategory === 'all' || $product['category'] === $this->shopCategory)
            ->filter(fn (array $product): bool => $this->shopSearch === '' || str_contains(strtolower($product['name'].' '.$product['description'].' '.$product['eyebrow']), strtolower($this->shopSearch)))
            ->values()
            ->all();
    }

    /** @return array<int, ContactRow> */
    public function getFilteredContactsProperty(): array
    {
        return Contact::query()
            ->when($this->search !== '', fn ($query) => $query->where('name', 'like', "%{$this->search}%")->orWhere('phone_number', 'like', "%{$this->search}%"))
            ->orderBy('name')
            ->get()
            ->map(function (Contact $contact): array {
                $name = (string) $contact->getAttribute('name');

                return [
                    'id' => (int) $contact->getKey(),
                    'name' => $name,
                    'phone_number' => (string) $contact->getAttribute('phone_number'),
                    'initials' => collect(explode(' ', $name))->map(fn (string $part): string => strtoupper(substr($part, 0, 1)))->take(2)->join(''),
                    'status' => $contact->getAttribute('status_bio'),
                    'is_registered' => (bool) ($contact->getAttribute('is_registered') ?? true),
                ];
            })->all();
    }

    /** @return array<int, CallRow> */
    public function getFilteredCallsProperty(): array
    {
        return collect($this->calls)
            ->filter(fn (array $call): bool => $this->search === '' || str_contains(strtolower($call['name'].' '.$call['number']), strtolower($this->search)))
            ->values()
            ->all();
    }

    /** @return array<int, array<string, mixed>> */
    public function getStatusUpdatesProperty(): array
    {
        return Status::query()
            ->where('expires_at', '>', now())
            ->latest()
            ->get()
            ->map(fn (Status $status): array => array_merge($status->toArray(), [
                'created_at_label' => $status->getAttribute('created_at')?->format('M j, g:i A'),
            ]))
            ->all();
    }

    /** @return array<int, array<string, mixed>> */
    public function getRecentStatusesProperty(): array
    {
        return collect($this->statusUpdates)->where('is_viewed', false)->values()->all();
    }

    /** @return array<int, array<string, mixed>> */
    public function getViewedStatusesProperty(): array
    {
        return collect($this->statusUpdates)->where('is_viewed', true)->values()->all();
    }

    /** @return array<string, mixed>|null */
    public function getActiveStatusProperty(): ?array
    {
        return collect($this->statusUpdates)->firstWhere('id', $this->activeStatusId);
    }

    public function openStatusCreator(string $mode = 'text'): void
    {
        $this->resetValidation();
        $this->statusMode = $mode;
        $this->showStatusCreator = true;
    }

    public function closeStatusCreator(): void
    {
        $this->showStatusCreator = false;
        $this->reset(['statusText', 'statusCaption', 'statusMedia']);
        $this->statusMode = 'text';
    }

    public function publishStatus(): void
    {
        $rules = [
            'statusMode' => ['required', 'in:text,media'],
            'statusCaption' => ['nullable', 'string', 'max:2000'],
            'statusPrivacy' => ['required', 'in:Contacts,Everyone'],
            'statusBackground' => ['required', 'regex:/^#[0-9a-fA-F]{6}$/'],
            'statusFont' => ['required', 'in:sans,serif,mono'],
        ];

        if ($this->statusMode === 'text') {
            $rules['statusText'] = ['required', 'string', 'max:700'];
        } else {
            $rules['statusMedia'] = ['required', 'file', 'mimes:jpg,jpeg,png,webp,mp4,mov', 'max:51200'];
        }

        $validated = $this->validate($rules);
        $mediaPath = $this->statusMode === 'media' ? $this->statusMedia->store('statuses', 'public') : null;

        Status::create([
            'body' => $this->statusMode === 'text' ? $validated['statusText'] : null,
            'media_path' => $mediaPath,
            'media_type' => $this->statusMode,
            'caption' => $validated['statusCaption'],
            'privacy' => $validated['statusPrivacy'],
            'background' => $validated['statusBackground'],
            'font' => $validated['statusFont'],
            'author_name' => $this->displayName,
            'author_initials' => strtoupper(substr($this->displayName, 0, 2)),
            'is_viewed' => true,
            'expires_at' => now()->addDay(),
        ]);

        $this->closeStatusCreator();
        Flux::toast(variant: 'success', text: 'Your status was posted.');
    }

    public function openStatus(int $statusId): void
    {
        $status = Status::findOrFail($statusId);
        $status->update(['is_viewed' => true]);
        $this->activeStatusId = $statusId;
        $statusIndex = collect($this->statusUpdates)->pluck('id')->search($statusId);
        $this->activeStatusIndex = is_int($statusIndex) ? $statusIndex : 0;
        $this->statusPaused = false;
    }

    public function closeStatusViewer(): void
    {
        $this->activeStatusId = null;
    }

    public function nextStatus(): void
    {
        $ids = collect($this->statusUpdates)->pluck('id')->values();
        if ($ids->isEmpty()) {
            return;
        }
        $this->activeStatusIndex = min($this->activeStatusIndex + 1, $ids->count() - 1);
        $this->openStatus((int) $ids[$this->activeStatusIndex]);
    }

    public function previousStatus(): void
    {
        $ids = collect($this->statusUpdates)->pluck('id')->values();
        if ($ids->isEmpty()) {
            return;
        }
        $this->activeStatusIndex = max($this->activeStatusIndex - 1, 0);
        $this->openStatus((int) $ids[$this->activeStatusIndex]);
    }

    public function toggleStatusPlayback(): void
    {
        $this->statusPaused = ! $this->statusPaused;
    }

    public function toggleStatusMute(): void
    {
        $this->statusMuted = ! $this->statusMuted;
    }

    public function sendStatusReply(): void
    {
        $this->validate(['statusReply' => ['required', 'string', 'max:1000']]);
        $this->reset('statusReply');
        Flux::toast(variant: 'success', text: 'Status reply sent.');
    }

    public function openFavoritePicker(): void
    {
        $this->showFavoritePicker = true;
    }

    public function closeFavoritePicker(): void
    {
        $this->showFavoritePicker = false;
    }

    public function addFavorite(string $number): void
    {
        $call = collect($this->calls)->firstWhere('number', $number);

        if ($call && ! collect($this->favorites)->contains('number', $number)) {
            $this->favorites[] = $call;
        }

        $this->showFavoritePicker = false;
    }

    public function removeFavorite(string $number): void
    {
        $this->favorites = collect($this->favorites)
            ->reject(fn (array $favorite): bool => $favorite['number'] === $number)
            ->values()
            ->all();
    }

    public function openDialpad(string $number = ''): void
    {
        $this->dialNumber = $number;
        $this->showDialpad = true;
    }

    public function closeDialpad(): void
    {
        $this->showDialpad = false;
    }

    public function appendDialDigit(string $digit): void
    {
        if (preg_match('/^[0-9*#+]$/', $digit) === 1) {
            $this->dialNumber .= $digit;
        }
    }

    public function removeDialDigit(): void
    {
        $this->dialNumber = substr($this->dialNumber, 0, -1);
    }

    public function clearDialNumber(): void
    {
        $this->dialNumber = '';
    }

    public function openCallInterface(string $number, ?string $name = null): void
    {
        $number = preg_replace('/[^0-9*#+]/', '', $number) ?? '';
        $digits = preg_replace('/\D/', '', $number) ?? '';

        if (strlen($digits) < 3) {
            Flux::toast(variant: 'danger', text: 'Enter a valid phone number first.');

            return;
        }

        $call = collect($this->calls)->first(fn (array $entry): bool => preg_replace('/[^0-9*#+]/', '', $entry['number']) === $number);
        $this->callName = $name ?: ($call['name'] ?? $number);
        $this->callNumber = $number;
        $this->callSpeaker = false;
        $this->callMuted = false;
        $this->callVideo = false;
        $this->callMoreOpen = false;
        $this->showDialpad = false;
        $this->showCallScreen = true;
    }

    public function toggleCallControl(string $control): void
    {
        match ($control) {
            'speaker' => $this->callSpeaker = ! $this->callSpeaker,
            'mute' => $this->callMuted = ! $this->callMuted,
            'video' => $this->callVideo = ! $this->callVideo,
            'more' => $this->callMoreOpen = ! $this->callMoreOpen,
            default => null,
        };
    }

    public function callActiveConversation(): void
    {
        $name = $this->activeConversation['name'];
        $call = collect($this->calls)->firstWhere('name', $name);

        if (! $call) {
            Flux::toast(variant: 'danger', text: 'No phone number is available for this contact.');

            return;
        }

        $this->openCallInterface($call['number'], $name);
    }

    public function shareCallNumber(): void
    {
        $this->dispatch('share-call-number', number: $this->callNumber);
    }

    public function closeCallInterface(): void
    {
        $this->showCallScreen = false;
    }

    public function handoffCall(): void
    {
        if ($this->showCallScreen) {
            $this->dispatch('call-number', number: $this->callNumber);
        }
    }

    public function startCall(): void
    {
        $number = preg_replace('/[^0-9*#+]/', '', $this->dialNumber) ?? '';
        $digits = preg_replace('/\D/', '', $number) ?? '';

        if (strlen($digits) < 3) {
            Flux::toast(variant: 'danger', text: 'Enter a valid phone number first.');

            return;
        }

        $this->dialNumber = $number;
        $this->calls = array_merge([
            [
                'name' => $number,
                'number' => $number,
                'initials' => substr($number, 0, 3),
                'direction' => 'outbound',
                'time' => 'Just now',
                'duration' => '',
                'missed' => false,
            ],
        ], collect($this->calls)->reject(fn (array $call): bool => $call['number'] === $number)->values()->all());
        $this->showDialpad = false;
        $this->openCallInterface($number, $number);
    }

    public function selectConversation(int $conversationId): void
    {
        $this->activeConversationId = $conversationId;
        $this->showConversation = true;
        $this->showEmojiPicker = false;
        $this->showContactProfile = false;
        $this->conversations = collect($this->conversations)->map(function (array $conversation) use ($conversationId): array {
            if ($conversation['id'] === $conversationId) {
                $conversation['unread'] = 0;
            }

            return $conversation;
        })->all();
    }

    public function backToChats(): void
    {
        $this->showConversation = false;
        $this->showEmojiPicker = false;
    }

    public function toggleEmojiPicker(): void
    {
        $this->showEmojiPicker = ! $this->showEmojiPicker;
    }

    public function insertEmoji(string $emoji): void
    {
        $this->messageDraft .= $emoji;
    }

    /** @return array<string, bool|string> */
    public function getActiveConversationPreferencesProperty(): array
    {
        return array_merge(
            ['disappearing' => 'off', 'blocked' => false, 'reported' => false],
            $this->conversationPreferences[$this->activeConversationId] ?? [],
        );
    }

    public function openContactProfile(): void
    {
        $this->showContactProfile = true;
    }

    public function closeContactProfile(): void
    {
        $this->showContactProfile = false;
    }

    public function setDisappearingMessages(string $duration): void
    {
        if (! in_array($duration, ['off', '24h', '7d', '90d'], true)) {
            return;
        }

        $this->conversationPreferences[$this->activeConversationId]['disappearing'] = $duration;
    }

    public function clearChat(): void
    {
        $this->conversations = collect($this->conversations)->map(function (array $conversation): array {
            if ($conversation['id'] === $this->activeConversationId) {
                $conversation['messages'] = [];
                $conversation['preview'] = '';
            }

            return $conversation;
        })->all();

        $this->showContactProfile = false;
        Flux::toast(variant: 'success', text: 'Messages cleared from this device.');
    }

    public function toggleBlockContact(): void
    {
        $blocked = ! $this->activeConversationPreferences['blocked'];
        $this->conversationPreferences[$this->activeConversationId]['blocked'] = $blocked;
        $this->showContactProfile = false;

        Flux::toast(variant: 'success', text: $blocked ? 'Contact blocked for this session.' : 'Contact unblocked.');
    }

    public function reportContact(): void
    {
        $this->conversationPreferences[$this->activeConversationId]['reported'] = true;
        $this->showContactProfile = false;

        Flux::toast(variant: 'success', text: 'Contact marked as reported for this session.');
    }

    public function selectContact(int $contactId): void
    {
        $contact = Contact::findOrFail($contactId);
        $phoneNumber = (string) $contact->getAttribute('phone_number');
        $name = (string) $contact->getAttribute('name');
        $statusBio = $contact->getAttribute('status_bio');
        $conversation = Conversation::firstOrCreate(
            ['phone_number' => $phoneNumber],
            ['name' => $name],
        );

        $existing = collect($this->conversations)->firstWhere('id', $conversation->id);

        if (! $existing) {
            $this->conversations[] = [
                'id' => $conversation->id,
                'name' => $name,
                'initials' => strtoupper(substr($name, 0, 1)),
                'tone' => 'bg-stone-400',
                'time' => 'New',
                'preview' => 'New SMS conversation',
                'status' => (string) ($statusBio ?? 'SMS contact'),
                'unread' => 0,
                'messages' => [],
            ];
        }

        $this->activeConversationId = $conversation->id;
        $this->showConversation = true;
        $this->leftPanel = 'chats';
    }

    public function showPanel(string $panel): void
    {
        $this->leftPanel = $panel;
        $this->showConversation = false;
        $this->showEmojiPicker = false;
        $this->search = '';
    }

    public function filterShop(string $category): void
    {
        $this->shopCategory = $category;
    }

    public function topUpCredits(): void
    {
        Flux::toast(variant: 'danger', text: 'Payments are not configured. No credits were added.');
    }

    public function purchaseShopProduct(string $productId): void
    {
        $product = collect($this->shopProducts)->firstWhere('id', $productId);

        if (! $product) {
            return;
        }

        Flux::toast(variant: 'danger', text: 'Payments are not configured. No purchase was made.');
    }

    public function openContactForm(): void
    {
        $this->showWebContactNotice = true;
    }

    public function prepareContactForm(): void
    {
        $this->showWebContactNotice = false;
        $this->resetValidation();
        $this->reset(['contactFirstName', 'contactLastName', 'contactPhone']);
        $this->showContactForm = true;
    }

    public function closeWebContactNotice(): void
    {
        $this->showWebContactNotice = false;
    }

    /** @return array<int, ContactRow> */
    public function getRegisteredContactsProperty(): array
    {
        return collect($this->filteredContacts)->filter(fn (array $contact): bool => $contact['is_registered'])->values()->all();
    }

    /** @return array<int, array{name: string, phone_number: string, initials: string}> */
    public function getInviteContactsProperty(): array
    {
        $registeredNumbers = Contact::query()->pluck('phone_number')->map(fn (string $number): string => preg_replace('/\s+/', '', $number))->all();

        return collect($this->deviceContacts)
            ->filter(function (array $contact) use ($registeredNumbers): bool {
                $number = preg_replace('/\s+/', '', $contact['phone_number']);

                return ! in_array($number, $registeredNumbers, true)
                    && ($this->search === '' || str_contains(strtolower($contact['name'].' '.$contact['phone_number']), strtolower($this->search)));
            })
            ->values()
            ->all();
    }

    public function closeContactForm(): void
    {
        $this->showContactForm = false;
    }

    public function saveContact(): void
    {
        $validated = $this->validate([
            'contactFirstName' => ['required', 'string', 'max:255'],
            'contactLastName' => ['nullable', 'string', 'max:255'],
            'contactPhone' => ['required', 'regex:/^\+[1-9]\d{7,14}$/'],
        ], [
            'contactPhone.regex' => 'Use an international number such as +255712884102.',
        ]);

        $name = trim($validated['contactFirstName'].' '.$validated['contactLastName']);
        $contact = Contact::updateOrCreate(['phone_number' => $validated['contactPhone']], [
            'name' => $name,
            'status_bio' => 'SMS contact',
            'payload_prefix' => $this->contactPayloadPrefix,
        ]);

        $conversation = Conversation::firstOrCreate(
            ['phone_number' => $validated['contactPhone']],
            ['name' => $name],
        );

        $this->conversations[] = [
            'id' => $conversation->id,
            'name' => $name,
            'initials' => strtoupper(substr($name, 0, 1).substr(strstr($name, ' ') ?: $name, 1, 1)),
            'tone' => 'bg-stone-400',
            'time' => 'New',
            'preview' => 'New SMS conversation',
            'status' => 'SMS contact',
            'unread' => 0,
            'messages' => [],
        ];
        $this->activeConversationId = $conversation->id;
        $this->showContactForm = false;
        $this->leftPanel = 'chats';
    }

    public function openSettings(): void
    {
        $this->showSettings = true;
    }

    public function closeSettings(): void
    {
        $this->showSettings = false;
    }

    public function selectSetting(string $setting): void
    {
        $this->activeSetting = $setting;
    }

    public function sendMessage(): void
    {
        if ($this->activeConversationPreferences['blocked']) {
            return;
        }

        $body = trim($this->messageDraft);

        if ($body === '') {
            return;
        }

        $this->showEmojiPicker = false;

        $this->conversations = collect($this->conversations)->map(function (array $conversation) use ($body): array {
            if ($conversation['id'] === $this->activeConversationId) {
                $message = [
                    'body' => $body,
                    'time' => now()->format('g:i A'),
                    'mine' => true,
                ];

                $expiry = match ($this->activeConversationPreferences['disappearing']) {
                    '24h' => now()->addDay(),
                    '7d' => now()->addDays(7),
                    '90d' => now()->addDays(90),
                    default => null,
                };

                if ($expiry) {
                    $message['expires_at'] = $expiry->toIso8601String();
                }

                $conversation['messages'][] = $message;
                $conversation['preview'] = $body;
                $conversation['time'] = 'Now';
            }

            return $conversation;
        })->all();

        $this->reset('messageDraft');
    }

    public function render(): View
    {
        return view('livewire.whats-app-chat');
    }
}
