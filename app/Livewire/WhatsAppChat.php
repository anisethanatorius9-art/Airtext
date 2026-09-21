<?php

namespace App\Livewire;

use App\Models\Contact;
use App\Models\Conversation;
use App\Models\Status;
use Flux\Flux;
use Livewire\Attributes\Layout;
use Livewire\Component;
use Livewire\WithFileUploads;

#[Layout('components.layouts.whatsapp')]
class WhatsAppChat extends Component
{
    use WithFileUploads;

    public string $search = '';

    public string $filter = 'All';

    public string $messageDraft = '';

    public int $activeConversationId = 1;

    public bool $showSettings = false;

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

    public int $shopBalance = 1250;

    public array $shopProducts = [
        ['id' => 'credits-5000', 'category' => 'credits', 'icon' => 'cube', 'eyebrow' => '5,000 BULK SMS', 'name' => 'SMS Credits Package', 'description' => 'High-throughput local GSM routes for campaigns and alerts.', 'price' => 50000, 'price_label' => 'TZS 50,000', 'action' => 'Buy package'],
        ['id' => 'gemini-bot', 'category' => 'bots', 'icon' => 'cpu-chip', 'eyebrow' => 'GEMINI AI BOT', 'name' => 'AI Auto-Responder Bot', 'description' => 'Automated SMS customer support that replies around the clock.', 'price' => 15000, 'price_label' => 'TZS 15,000 / month', 'action' => 'Install bot'],
        ['id' => 'sender-id', 'category' => 'gateways', 'icon' => 'tag', 'eyebrow' => 'BRANDED SENDER ID', 'name' => 'Custom Sender ID', 'description' => 'Register a trusted business name for your outgoing messages.', 'price' => 30000, 'price_label' => 'TZS 30,000 / year', 'action' => 'Request ID'],
        ['id' => 'tourism-bot', 'category' => 'bots', 'icon' => 'sparkles', 'eyebrow' => 'READY TO DEPLOY', 'name' => 'Tourism Concierge Bot', 'description' => 'Answer booking and itinerary questions automatically.', 'price' => 12000, 'price_label' => 'TZS 12,000 / month', 'action' => 'Install bot'],
        ['id' => 'order-template', 'category' => 'templates', 'icon' => 'document-text', 'eyebrow' => 'MESSAGE TEMPLATE', 'name' => 'Order Updates Pack', 'description' => 'Prebuilt delivery, payment, and order notification flows.', 'price' => 8000, 'price_label' => 'TZS 8,000 one-time', 'action' => 'Get template'],
        ['id' => 'gsm-node', 'category' => 'gateways', 'icon' => 'signal', 'eyebrow' => '99.9% UPTIME', 'name' => 'Dedicated GSM Gateway Node', 'description' => 'A dedicated route for reliable business-critical SMS traffic.', 'price' => 45000, 'price_label' => 'TZS 45,000 / month', 'action' => 'Activate node'],
    ];

    public array $installedShopItems = [
        ['name' => 'Automated Tourism Concierge Bot', 'type' => 'AI bot', 'status' => 'Active', 'meta' => 'Expires in 18 days', 'icon' => 'sparkles'],
        ['name' => 'Dedicated GSM Gateway Node', 'type' => 'Gateway', 'status' => 'Active', 'meta' => 'Uptime 99.9%', 'icon' => 'signal'],
    ];

    public bool $showContactForm = false;
    public bool $showWebContactNotice = false;

    public bool $showFavoritePicker = false;

    public bool $showDialpad = false;

    public string $dialNumber = '';

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

    public $statusMedia;

    public string $contactFirstName = '';

    public string $contactLastName = '';

    public string $contactPhone = '';

    public string $contactPayloadPrefix = 'MSG:';
    public array $deviceContacts = [
        ['name' => 'Neema Studio', 'phone_number' => '+255 763 100 445', 'initials' => 'NS'],
        ['name' => 'Mariam Hassan', 'phone_number' => '+255 718 220 901', 'initials' => 'MH'],
    ];

    public array $calls = [
        ['name' => 'Juma K.', 'number' => '+255 712 884 102', 'initials' => 'JK', 'direction' => 'outbound', 'time' => 'Today, 10:14 AM', 'duration' => '04:32', 'missed' => false],
        ['name' => 'Unknown number', 'number' => '+255 782 328 215', 'initials' => '+255', 'direction' => 'inbound', 'time' => 'Today, 8:42 AM', 'duration' => '01:08', 'missed' => false],
        ['name' => 'Lina A.', 'number' => '+255 754 991 204', 'initials' => 'LA', 'direction' => 'inbound', 'time' => 'Yesterday, 6:20 PM', 'duration' => '', 'missed' => true],
    ];

    public array $channels = [
        ['name' => 'AirText updates', 'initials' => '✦', 'announcement' => 'Payload protocol updates and service news'],
        ['name' => 'Dar Studio Network', 'initials' => 'DS', 'announcement' => 'New studio announcements this week'],
    ];

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

    public function getActiveConversationProperty(): array
    {
        return collect($this->conversations)->firstWhere('id', $this->activeConversationId) ?? $this->conversations[0];
    }

    public function getFilteredConversationsProperty(): array
    {
        return collect($this->conversations)
            ->filter(fn (array $conversation): bool => $this->filter === 'All' || ($this->filter === 'Unread' && $conversation['unread'] > 0))
            ->filter(fn (array $conversation): bool => $this->search === '' || str_contains(strtolower($conversation['name']), strtolower($this->search)))
            ->values()
            ->all();
    }

    public function getFilteredShopProductsProperty(): array
    {
        return collect($this->shopProducts)
            ->filter(fn (array $product): bool => $this->shopCategory === 'all' || $product['category'] === $this->shopCategory)
            ->filter(fn (array $product): bool => $this->shopSearch === '' || str_contains(strtolower($product['name'].' '.$product['description'].' '.$product['eyebrow']), strtolower($this->shopSearch)))
            ->values()
            ->all();
    }

    public function getFilteredContactsProperty(): array
    {
        return Contact::query()
            ->when($this->search !== '', fn ($query) => $query->where('name', 'like', "%{$this->search}%")->orWhere('phone_number', 'like', "%{$this->search}%"))
            ->orderBy('name')
            ->get()
            ->map(fn (Contact $contact): array => [
                'id' => $contact->id,
                'name' => $contact->name,
                'phone_number' => $contact->phone_number,
                'initials' => collect(explode(' ', $contact->name))->map(fn (string $part): string => strtoupper(substr($part, 0, 1)))->take(2)->join(''),
                'status' => $contact->status_bio,
                'is_registered' => (bool) ($contact->is_registered ?? true),
            ])->all();
    }

    public function getFilteredCallsProperty(): array
    {
        return collect($this->calls)
            ->filter(fn (array $call): bool => $this->search === '' || str_contains(strtolower($call['name'].' '.$call['number']), strtolower($this->search)))
            ->values()
            ->all();
    }

    public function getStatusUpdatesProperty(): array
    {
        return Status::query()
            ->where('expires_at', '>', now())
            ->latest()
            ->get()
            ->map(fn (Status $status): array => array_merge($status->toArray(), [
                'created_at_label' => $status->created_at?->format('M j, g:i A'),
            ]))
            ->all();
    }

    public function getRecentStatusesProperty(): array
    {
        return collect($this->statusUpdates)->where('is_viewed', false)->values()->all();
    }

    public function getViewedStatusesProperty(): array
    {
        return collect($this->statusUpdates)->where('is_viewed', true)->values()->all();
    }

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
        $this->activeStatusIndex = collect($this->statusUpdates)->pluck('id')->search($statusId) ?: 0;
        $this->statusPaused = false;
    }

    public function closeStatusViewer(): void
    {
        $this->activeStatusId = null;
    }

    public function nextStatus(): void
    {
        $ids = collect($this->statusUpdates)->pluck('id')->values();
        if ($ids->isEmpty()) return;
        $this->activeStatusIndex = min($this->activeStatusIndex + 1, $ids->count() - 1);
        $this->openStatus((int) $ids[$this->activeStatusIndex]);
    }

    public function previousStatus(): void
    {
        $ids = collect($this->statusUpdates)->pluck('id')->values();
        if ($ids->isEmpty()) return;
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

        Flux::toast(variant: 'success', text: "Calling {$number}...");
        $this->dispatch('call-number', number: $number);
    }

    public function selectConversation(int $conversationId): void
    {
        $this->activeConversationId = $conversationId;
        $this->conversations = collect($this->conversations)->map(function (array $conversation) use ($conversationId): array {
            if ($conversation['id'] === $conversationId) {
                $conversation['unread'] = 0;
            }

            return $conversation;
        })->all();
    }

    public function selectContact(int $contactId): void
    {
        $contact = Contact::findOrFail($contactId);
        $conversation = Conversation::firstOrCreate(
            ['phone_number' => $contact->phone_number],
            ['name' => $contact->name],
        );

        $existing = collect($this->conversations)->firstWhere('id', $conversation->id);

        if (! $existing) {
            $this->conversations[] = [
                'id' => $conversation->id,
                'name' => $contact->name,
                'initials' => strtoupper(substr($contact->name, 0, 1)),
                'tone' => 'bg-stone-400',
                'time' => 'New',
                'preview' => 'New SMS conversation',
                'status' => $contact->status_bio ?? 'SMS contact',
                'unread' => 0,
                'messages' => [],
            ];
        }

        $this->activeConversationId = $conversation->id;
        $this->leftPanel = 'chats';
    }

    public function showPanel(string $panel): void
    {
        $this->leftPanel = $panel;
        $this->search = '';
    }

    public function filterShop(string $category): void
    {
        $this->shopCategory = $category;
    }

    public function topUpCredits(): void
    {
        $this->shopBalance += 1000;
        Flux::toast(variant: 'success', text: '1,000 SMS credits added to your wallet.');
    }

    public function purchaseShopProduct(string $productId): void
    {
        $product = collect($this->shopProducts)->firstWhere('id', $productId);

        if (! $product) {
            return;
        }

        if ($product['category'] === 'credits') {
            $this->shopBalance += 5000;
            Flux::toast(variant: 'success', text: '5,000 SMS credits added to your wallet.');

            return;
        }

        if (! collect($this->installedShopItems)->contains('name', $product['name'])) {
            $this->installedShopItems[] = [
                'name' => $product['name'],
                'type' => ucfirst($product['category']),
                'status' => 'Active',
                'meta' => 'Ready to configure',
                'icon' => $product['icon'],
            ];
        }

        Flux::toast(variant: 'success', text: "{$product['name']} added to your services.");
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

    public function getRegisteredContactsProperty(): array
    {
        return collect($this->filteredContacts)->filter(fn (array $contact): bool => $contact['is_registered'])->values()->all();
    }

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
            ['phone_number' => $contact->phone_number],
            ['name' => $contact->name],
        );

        $this->conversations[] = [
            'id' => $conversation->id,
            'name' => $contact->name,
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
        $body = trim($this->messageDraft);

        if ($body === '') {
            return;
        }

        $this->conversations = collect($this->conversations)->map(function (array $conversation) use ($body): array {
            if ($conversation['id'] === $this->activeConversationId) {
                $conversation['messages'][] = [
                    'body' => $body,
                    'time' => now()->format('g:i A'),
                    'mine' => true,
                ];
                $conversation['preview'] = $body;
                $conversation['time'] = 'Now';
            }

            return $conversation;
        })->all();

        $this->reset('messageDraft');
    }

    public function render()
    {
        return view('livewire.whats-app-chat');
    }
}
