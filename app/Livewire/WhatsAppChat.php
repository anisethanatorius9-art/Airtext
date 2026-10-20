<?php

namespace App\Livewire;

use App\Models\Channel;
use App\Models\Contact;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\ShopTransaction;
use App\Models\Status;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Models\User;
use App\Models\UserInstalledBot;
use App\Services\ShopSubscriptionCheckout;
use App\Services\SubscriptionEntitlements;
use Flux\Flux;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;
use Livewire\Attributes\Layout;
use Livewire\Component;
use Livewire\WithFileUploads;

/**
 * @phpstan-type ShopProduct array{id: string, category: string, icon: string, eyebrow: string, name: string, description: string, price: int, price_label: string, action: string, is_installed?: bool}
 * @phpstan-type ContactRow array{id: int, name: string, phone_number: string, initials: string, status: mixed, is_registered: bool}
 * @phpstan-type CallRow array{name: string, number: string, initials: string, direction: string, time: string, duration: string, missed: bool}
 * @phpstan-type ChatMessageRow array{body: string, time: string, mine: bool, expires_at?: string, code?: bool, attachment?: bool, attachment_type?: string, attachment_url?: string}
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

    public mixed $messageAttachment = null;

    public int $activeConversationId = 1;

    public bool $showConversation = false;

    public bool $showEmojiPicker = false;

    public bool $showSettings = false;

    public bool $showStorageDetails = false;

    public bool $showNetworkDetails = false;

    public bool $showProxyDetails = false;

    public bool $showContactProfile = false;

    /** @var array<int, array<string, bool|string>> */
    public array $conversationPreferences = [];

    public string $activeSetting = 'profile';

    public string $displayName = '@amjunior89';

    public string $phoneNumber = '+255 712 884 102';

    public string $lastSeenVisibility = 'Everyone';

    public string $profilePictureVisibility = 'My contacts';

    public string $statusVisibility = 'Everyone';

    public mixed $profilePhoto = null;

    public string $profilePhotoUrl = '';

    public string $payloadPrefix = 'MSG:';

    public string $gatewayDriver = 'Africa\'s Talking';

    public bool $deliveryAlerts = true;

    public bool $lowBalanceAlerts = true;

    public bool $useLessDataForCalls = false;

    public string $uploadQuality = 'hd';

    public string $autoDownloadQuality = 'auto';

    public string $mobileDataDownloads = 'photos';

    public string $wifiDownloads = 'all';

    public string $roamingDownloads = 'none';

    public string $leftPanel = 'chats';

    /** @var array<int, string> */
    public array $dismissedSystemNotifications = [];

    public string $shopSearch = '';

    public string $shopCategory = 'all';

    public string $shopSection = 'browse';

    public ?string $selectedSubscriptionPlanCode = null;

    public string $subscriptionPhoneNumber = '';

    public string $subscriptionGateway = 'azampay';

    public bool $showSubscriptionCheckout = false;

    /** @var array<int, ShopProduct> */
    public array $shopProducts = [];

    /** @var array<int, array<string, string>> */
    public array $installedShopItems = [];

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

    public bool $showChannelComposer = false;

    public string $channelName = '';

    public string $channelDescription = '';

    public ?int $activeStatusId = null;

    public int $activeStatusIndex = 0;

    public bool $statusPaused = false;

    public bool $statusMuted = false;

    public bool $statusLiked = false;

    public string $statusMode = 'text';

    public string $statusText = '';

    public string $statusCaption = '';

    public string $statusReply = '';

    public string $statusPrivacy = 'Contacts';

    public bool $statusViewOnce = false;

    public bool $statusScreenshotProtected = true;

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
            'is_online' => true,
            'typing' => false,
            'last_seen' => 'last seen 2m ago',
            'profile_photo_url' => null,
            'is_favorite' => false,
            'is_group' => false,
            'messages' => [
                ['body' => 'Can you give me the payload code for AirText SMS parsing?', 'time' => '10:41 AM', 'mine' => false, 'status' => 'read'],
                ['body' => 'class SmsPayloadService { return "MSG:{$content}"; }', 'time' => '10:42 AM', 'mine' => true, 'code' => true, 'status' => 'read'],
                ['body' => 'AirText_SDLC_Documentation.docx', 'time' => '10:45 AM', 'mine' => true, 'attachment' => true, 'status' => 'delivered'],
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
            'is_online' => false,
            'typing' => true,
            'last_seen' => 'last seen 3m ago',
            'profile_photo_url' => null,
            'is_favorite' => false,
            'is_group' => false,
            'messages' => [
                ['body' => 'Ni vizuri sana mimi ni yale software...', 'time' => '5:51 AM', 'mine' => false, 'status' => 'delivered'],
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
            'is_online' => true,
            'typing' => false,
            'last_seen' => 'online now',
            'profile_photo_url' => null,
            'is_favorite' => true,
            'is_group' => false,
            'messages' => [
                ['body' => 'The studio address is on its way.', 'time' => 'Yesterday', 'mine' => false, 'status' => 'read'],
            ],
        ],
    ];

    /** @return ConversationRow */
    public function getActiveConversationProperty(): array
    {
        $conversation = collect($this->conversations)->firstWhere('id', $this->activeConversationId) ?? $this->conversations[0];
        $conversation['messages'] = collect($conversation['messages'])
            ->reject(fn(array $message): bool => isset($message['expires_at']) && now()->greaterThanOrEqualTo($message['expires_at']))
            ->values()
            ->all();

        $user = Auth::user();
        if ($user instanceof User) {
            $conversation['messages'] = [
                ...$conversation['messages'],
                ...$this->storedAttachmentMessages($user, $conversation),
            ];
        }

        return $conversation;
    }

    /** @return array<int, ChatMessageRow> */
    private function storedAttachmentMessages(User $user, array $conversation): array
    {
        $databaseConversation = $this->findAttachmentConversation($user, $conversation);
        if (! $databaseConversation instanceof Conversation) {
            return [];
        }

        return $databaseConversation->messages()
            ->where('sender_id', $user->id)
            ->whereIn('message_type', ['image', 'document'])
            ->oldest('sent_at')
            ->get()
            ->map(fn(Message $message): array => [
                'body' => $message->body,
                'time' => $message->sent_at?->format('g:i A') ?? $message->created_at?->format('g:i A') ?? '',
                'mine' => true,
                'attachment' => true,
                'attachment_type' => $message->message_type,
                'attachment_url' => route('chat.attachments.show', [
                    'conversation' => $databaseConversation->id,
                    'message' => $message->id,
                ]),
                'status' => $message->status,
            ])
            ->all();
    }

    private function findAttachmentConversation(User $user, array $chat): ?Conversation
    {
        $phoneNumber = $this->attachmentPhoneNumber($user, $chat);
        $query = $user->ownedConversations()
            ->whereNull('recipient_id')
            ->where('name', $chat['name']);

        return $phoneNumber === null
            ? $query->whereNull('phone_number')->first()
            : $query->where('phone_number', $phoneNumber)->first();
    }

    /** @param array<string, mixed> $chat */
    private function attachmentPhoneNumber(User $user, array $chat): ?string
    {
        if (($chat['id'] ?? null) === 1 && $user->phone_number !== null) {
            return preg_replace('/\s+/', '', $user->phone_number);
        }

        $name = (string) ($chat['name'] ?? '');
        if (preg_match('/^\+[1-9]\d{7,14}$/', $name) === 1) {
            return $name;
        }

        return null;
    }

    /** @return array<int, ConversationRow> */
    public function getFilteredConversationsProperty(): array
    {
        return collect($this->conversations)
            ->filter(function (array $conversation): bool {
                return match ($this->filter) {
                    'Unread' => $conversation['unread'] > 0,
                    'Favourites' => (bool) ($conversation['is_favorite'] ?? false),
                    'Groups' => (bool) ($conversation['is_group'] ?? false),
                    default => true,
                };
            })
            ->filter(fn(array $conversation): bool => $this->search === '' || str_contains(strtolower($conversation['name']), strtolower($this->search)))
            ->values()
            ->all();
    }

    /** @return array{conversation_count: int, message_count: int, voice_count: int, storage_bytes: int, sms_conversation_count: int, sms_message_count: int} */
    public function getStorageSummaryProperty(): array
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            return ['conversation_count' => 0, 'message_count' => 0, 'voice_count' => 0, 'storage_bytes' => 0, 'sms_conversation_count' => 0, 'sms_message_count' => 0];
        }

        $conversationIds = Conversation::query()
            ->where(fn($query) => $query->where('owner_id', $user->id)->orWhere('recipient_id', $user->id))
            ->pluck('id');
        $smsConversationIds = $user->ownedConversations()->whereNull('recipient_id')->pluck('id');
        $voicePaths = Message::query()
            ->whereIn('conversation_id', $conversationIds)
            ->where('sender_id', $user->id)
            ->whereNotNull('media_path')
            ->pluck('media_path');
        $disk = Storage::disk('local');
        $storageBytes = $voicePaths->unique()->sum(fn(string $path): int => $disk->exists($path) ? $disk->size($path) : 0);

        return [
            'conversation_count' => $conversationIds->count(),
            'message_count' => Message::query()->whereIn('conversation_id', $conversationIds)->count(),
            'voice_count' => $voicePaths->count(),
            'storage_bytes' => $storageBytes,
            'sms_conversation_count' => $smsConversationIds->count(),
            'sms_message_count' => Message::query()->whereIn('conversation_id', $smsConversationIds)->count(),
        ];
    }

    /** @return array{uploaded_bytes: int, downloaded_bytes: int, request_count: int, period_label: string} */
    public function getNetworkUsageSummaryProperty(): array
    {
        $user = Auth::user();
        $periodStart = now()->startOfMonth()->toDateString();
        $usage = $user instanceof User
            ? DB::table('user_network_usage')->where('user_id', $user->id)->where('period_start', $periodStart)->first()
            : null;

        return [
            'uploaded_bytes' => (int) ($usage->uploaded_bytes ?? 0),
            'downloaded_bytes' => (int) ($usage->downloaded_bytes ?? 0),
            'request_count' => (int) ($usage->request_count ?? 0),
            'period_label' => now()->format('F Y'),
        ];
    }

    public function saveStorageSettings(): void
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in to save Storage and data preferences.');

            return;
        }

        $settings = $this->validate([
            'useLessDataForCalls' => ['boolean'],
            'uploadQuality' => ['required', 'in:standard,hd'],
            'autoDownloadQuality' => ['required', 'in:auto,high'],
            'mobileDataDownloads' => ['required', 'in:none,photos,all'],
            'wifiDownloads' => ['required', 'in:none,photos,all'],
            'roamingDownloads' => ['required', 'in:none,photos,all'],
        ]);

        $user->forceFill([
            'storage_settings' => array_merge($user->storage_settings ?? [], [
                'use_less_data_for_calls' => $settings['useLessDataForCalls'],
                'upload_quality' => $settings['uploadQuality'],
                'auto_download_quality' => $settings['autoDownloadQuality'],
                'mobile_data_downloads' => $settings['mobileDataDownloads'],
                'wifi_downloads' => $settings['wifiDownloads'],
                'roaming_downloads' => $settings['roamingDownloads'],
            ]),
        ])->save();

        Flux::toast(variant: 'success', text: 'Storage and data preferences saved.');
    }

    public function backFromStorageSettings(): void
    {
        if ($this->showStorageDetails) {
            $this->showStorageDetails = false;

            return;
        }

        if ($this->showNetworkDetails || $this->showProxyDetails) {
            $this->showNetworkDetails = false;
            $this->showProxyDetails = false;

            return;
        }

        $this->activeSetting = 'profile';
    }

    public function openStorageDetails(): void
    {
        $this->showStorageDetails = true;
    }

    public function openNetworkDetails(): void
    {
        $this->showNetworkDetails = true;
    }

    public function openProxyDetails(): void
    {
        $this->showProxyDetails = true;
    }

    /** @return array<int, array{id: int, name: string, message_count: int}> */
    public function getStoredSmsConversationsProperty(): array
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            return [];
        }

        return $user->ownedConversations()
            ->whereNull('recipient_id')
            ->withCount('messages')
            ->latest('updated_at')
            ->get(['id', 'name'])
            ->map(fn(Conversation $conversation): array => [
                'id' => $conversation->id,
                'name' => $conversation->name,
                'message_count' => $conversation->messages_count,
            ])
            ->all();
    }

    /** @return array<int, array<string, int|string>> */
    /** @return array<int, ShopProduct> */
    public function getFilteredShopProductsProperty(): array
    {
        $user = Auth::user();
        $installedProductIds = [];

        if ($user instanceof User) {
            $installedProductIds = $user->installedBots()
                ->where('status', 'active')
                ->pluck('bot_identifier')
                ->all();
        }

        return collect($this->shopProducts)
            ->map(function (array $product) use ($installedProductIds): array {
                $isInstalled = in_array($product['id'], $installedProductIds, true);

                return [
                    ...$product,
                    'is_installed' => $isInstalled,
                    'action' => $isInstalled ? 'Installed' : $product['action'],
                ];
            })
            ->filter(fn(array $product): bool => $this->shopCategory === 'all' || $product['category'] === $this->shopCategory)
            ->filter(fn(array $product): bool => $this->shopSearch === '' || str_contains(strtolower($product['name'] . ' ' . $product['description'] . ' ' . $product['eyebrow']), strtolower($this->shopSearch)))
            ->values()
            ->all();
    }

    /** @return array<int, array{id: int, code: string, name: string, price_tzs: int, duration_days: ?int, description: string, features: array<int, string>}> */
    public function getSubscriptionPlansProperty(): array
    {
        return SubscriptionPlan::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get()
            ->map(fn(SubscriptionPlan $plan): array => [
                'id' => $plan->id,
                'code' => $plan->code,
                'name' => $plan->name,
                'price_tzs' => $plan->price_tzs,
                'duration_days' => $plan->duration_days,
                'description' => $plan->description,
                'features' => $plan->features,
            ])
            ->all();
    }

    public function getCurrentSubscriptionProperty(): ?Subscription
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            return null;
        }

        return $user->subscriptions()
            ->with('plan')
            ->where('status', 'active')
            ->where('activated_at', '<=', now())
            ->where(fn($query) => $query->whereNull('ends_at')->orWhere('ends_at', '>', now()))
            ->latest('activated_at')
            ->first();
    }

    public function getPendingSubscriptionProperty(): ?Subscription
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            return null;
        }

        return $user->subscriptions()
            ->with('plan')
            ->where('status', 'pending_payment')
            ->latest()
            ->first();
    }

    public function getUpcomingSubscriptionProperty(): ?Subscription
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            return null;
        }

        return $user->subscriptions()
            ->with('plan')
            ->where('status', 'active')
            ->where('activated_at', '>', now())
            ->orderBy('activated_at')
            ->first();
    }

    /** @return array<int, ContactRow> */
    public function getFilteredContactsProperty(): array
    {
        return Contact::query()
            ->when($this->search !== '', fn($query) => $query->where('name', 'like', "%{$this->search}%")->orWhere('phone_number', 'like', "%{$this->search}%"))
            ->orderBy('name')
            ->get()
            ->map(function (Contact $contact): array {
                $name = (string) $contact->getAttribute('name');

                return [
                    'id' => (int) $contact->getKey(),
                    'name' => $name,
                    'phone_number' => (string) $contact->getAttribute('phone_number'),
                    'initials' => collect(explode(' ', $name))->map(fn(string $part): string => strtoupper(substr($part, 0, 1)))->take(2)->join(''),
                    'status' => $contact->getAttribute('status_bio'),
                    'is_registered' => (bool) ($contact->getAttribute('is_registered') ?? true),
                ];
            })->all();
    }

    /** @return array<int, CallRow> */
    public function getFilteredCallsProperty(): array
    {
        return collect($this->calls)
            ->filter(fn(array $call): bool => $this->search === '' || str_contains(strtolower($call['name'] . ' ' . $call['number']), strtolower($this->search)))
            ->values()
            ->all();
    }

    /** @return array<int, array<string, mixed>> */
    public function getChannelListProperty(): array
    {
        $query = Channel::query()
            ->withCount('members')
            ->when($this->search !== '', fn($builder) => $builder
                ->where('name', 'like', "%{$this->search}%")
                ->orWhere('description', 'like', "%{$this->search}%"));

        return $query->latest()->get()->map(function (Channel $channel): array {
            $name = (string) $channel->getAttribute('name');
            $initials = collect(preg_split('/\s+/', trim($name)))->filter()->take(2)->map(fn(string $part): string => mb_substr($part, 0, 1))->implode('');

            return [
                'id' => (int) $channel->getKey(),
                'name' => $name,
                'initials' => $initials !== '' ? strtoupper($initials) : 'CH',
                'announcement' => (string) ($channel->getAttribute('description') ?: 'Community updates and announcements'),
                'members_count' => (int) ($channel->getAttribute('members_count') ?? 0),
            ];
        })->all();
    }

    /** @return array<int, array<string, mixed>> */
    public function getStatusUpdatesProperty(): array
    {
        return Status::query()
            ->withCount(['viewers', 'likes'])
            ->where('expires_at', '>', now())
            ->latest()
            ->get()
            ->map(fn(Status $status): array => array_merge($status->toArray(), [
                'created_at_label' => $status->getAttribute('created_at')?->format('M j, g:i A'),
                'viewers_count' => (int) ($status->getAttribute('viewers_count') ?? $status->viewers()->count()),
                'likes_count' => (int) ($status->getAttribute('likes_count') ?? $status->likes()->count()),
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
        $this->reset(['statusText', 'statusCaption', 'statusMedia', 'statusViewOnce', 'statusScreenshotProtected']);
        $this->statusMode = 'text';
        $this->statusPrivacy = 'Contacts';
    }

    public function publishStatus(): void
    {
        $rules = [
            'statusMode' => ['required', 'in:text,media'],
            'statusCaption' => ['nullable', 'string', 'max:2000'],
            'statusPrivacy' => ['required', 'in:Contacts,Everyone'],
            'statusViewOnce' => ['nullable', 'boolean'],
            'statusScreenshotProtected' => ['nullable', 'boolean'],
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
            'view_once' => (bool) $this->statusViewOnce,
            'screenshot_protected' => (bool) $this->statusScreenshotProtected,
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

    public function openChannelComposer(): void
    {
        $this->resetValidation();
        $this->showChannelComposer = true;
    }

    public function closeChannelComposer(): void
    {
        $this->showChannelComposer = false;
        $this->reset(['channelName', 'channelDescription']);
    }

    public function createChannel(): void
    {
        $this->validate([
            'channelName' => ['required', 'string', 'min:2', 'max:80'],
            'channelDescription' => ['nullable', 'string', 'max:500'],
        ]);

        $user = Auth::user() ?? User::query()->first();
        if ($user === null) {
            Flux::toast(variant: 'danger', text: 'You need an account before creating a channel.');

            return;
        }

        $channel = Channel::query()->create([
            'owner_id' => $user->id,
            'name' => trim($this->channelName),
            'slug' => str()->slug(trim($this->channelName)),
            'description' => trim($this->channelDescription) !== '' ? trim($this->channelDescription) : null,
            'is_public' => true,
        ]);

        $channel->members()->create([
            'user_id' => $user->id,
            'role' => 'admin',
            'joined_at' => now(),
        ]);

        $this->closeChannelComposer();
        $this->showPanel('channels');
        Flux::toast(variant: 'success', text: 'Channel created.');
    }

    public function openStatus(int $statusId): void
    {
        $status = Status::withCount(['viewers', 'likes'])->findOrFail($statusId);
        $status->update(['is_viewed' => true]);

        $this->activeStatusId = $statusId;
        $this->statusLiked = Auth::id() !== null && $status->likes()->where('user_id', Auth::id())->exists();
        $statusIndex = collect($this->statusUpdates)->pluck('id')->search($statusId);
        $this->activeStatusIndex = is_int($statusIndex) ? $statusIndex : 0;
        $this->statusPaused = false;
    }

    public function closeStatusViewer(): void
    {
        $this->activeStatusId = null;
    }

    public function toggleStatusLike(): void
    {
        $status = $this->activeStatus;
        if ($status === null) {
            return;
        }

        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in to like a status.');

            return;
        }

        $statusModel = Status::query()->findOrFail((int) $status['id']);
        if ($this->statusLiked) {
            $statusModel->likes()->detach($user->id);
            $this->statusLiked = false;
            Flux::toast(variant: 'success', text: 'Status unliked.');

            return;
        }

        $statusModel->likes()->syncWithoutDetaching([$user->id]);
        $this->statusLiked = true;
        Flux::toast(variant: 'success', text: 'Status liked.');
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
        $this->showDialpad = false;
        $this->showCallScreen = false;
        $this->callMoreOpen = false;
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
            ->reject(fn(array $favorite): bool => $favorite['number'] === $number)
            ->values()
            ->all();
    }

    public function openDialpad(string $number = ''): void
    {
        $this->dialNumber = $number;
        $this->showFavoritePicker = false;
        $this->showDialpad = true;
        $this->showCallScreen = false;
        $this->callMoreOpen = false;
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

        $call = collect($this->calls)->first(fn(array $entry): bool => preg_replace('/[^0-9*#+]/', '', $entry['number']) === $number);
        $this->callName = $name ?: ($call['name'] ?? $number);
        $this->callNumber = $number;
        $this->callSpeaker = false;
        $this->callMuted = false;
        $this->callVideo = false;
        $this->callMoreOpen = false;
        $this->showFavoritePicker = false;
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
        ], collect($this->calls)->reject(fn(array $call): bool => $call['number'] === $number)->values()->all());
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

    public function clearMessageAttachment(): void
    {
        $this->reset('messageAttachment');
    }

    private function createAttachmentConversation(User $user, array $chat): Conversation
    {
        $conversation = $this->findAttachmentConversation($user, $chat);
        if ($conversation instanceof Conversation) {
            return $conversation;
        }

        return $user->ownedConversations()->create([
            'name' => (string) $chat['name'],
            'phone_number' => $this->attachmentPhoneNumber($user, $chat),
            'recipient_id' => null,
        ]);
    }

    private function sendMessageAttachment(string $body): void
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in to upload an attachment.');

            return;
        }

        $this->validate([
            'messageAttachment' => [
                'required',
                'file',
                'max:20480',
                'mimes:jpg,jpeg,png,gif,webp,mp4,mov,pdf,txt,doc,docx,xls,xlsx,ppt,pptx,csv,zip',
            ],
        ]);

        $chat = $this->activeConversation;
        $conversation = $this->createAttachmentConversation($user, $chat);
        try {
            app(SubscriptionEntitlements::class)->assertStorageAvailable($user, (int) $this->messageAttachment->getSize());
        } catch (ValidationException $exception) {
            throw ValidationException::withMessages([
                'messageAttachment' => $exception->errors()['media'][0] ?? 'This upload exceeds your storage limit.',
            ]);
        }

        $mimeType = (string) $this->messageAttachment->getMimeType();
        $messageType = str_starts_with($mimeType, 'image/') ? 'image' : 'document';
        $mediaPath = $this->messageAttachment->store('message-attachments/'.$user->id, 'local');

        try {
            $message = DB::transaction(fn(): Message => $conversation->messages()->create([
                'sender_id' => $user->id,
                'direction' => 'outbound',
                'body' => $body !== '' ? $body : $this->messageAttachment->getClientOriginalName(),
                'message_type' => $messageType,
                'media_path' => $mediaPath,
                'payload_prefix' => $this->payloadPrefix,
                'status' => 'failed',
                'sent_at' => now(),
            ]));
        } catch (\Throwable $exception) {
            Storage::disk('local')->delete($mediaPath);

            throw $exception;
        }
        $conversation->touch();

        $this->conversations = collect($this->conversations)->map(function (array $item) use ($chat, $message): array {
            if ($item['id'] === $this->activeConversationId) {
                $item['preview'] = $message->body;
                $item['time'] = 'Now';
            }

            return $item;
        })->all();

        $this->reset(['messageDraft', 'messageAttachment']);
        $this->showEmojiPicker = false;
        Flux::toast(variant: 'danger', text: 'Attachment saved securely, but this SMS route cannot deliver media.');
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

    public function clearStoredSmsConversation(int $conversationId): void
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in to manage stored messages.');

            return;
        }

        $conversation = $user->ownedConversations()->whereNull('recipient_id')->find($conversationId);
        if (! $conversation instanceof Conversation) {
            Flux::toast(variant: 'danger', text: 'That SMS conversation is not available to this account.');

            return;
        }

        $mediaPaths = DB::transaction(function () use ($conversation): array {
            $mediaPaths = $conversation->messages()->whereNotNull('media_path')->pluck('media_path')->all();
            $conversation->messages()->delete();

            return $mediaPaths;
        });

        $this->deleteUnreferencedMessageMedia($mediaPaths);
        Flux::toast(variant: 'success', text: 'SMS history cleared.');
    }

    public function clearAllStoredSmsMessages(): void
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in to manage stored messages.');

            return;
        }

        $conversationIds = $user->ownedConversations()->whereNull('recipient_id')->pluck('id');
        $mediaPaths = DB::transaction(function () use ($conversationIds): array {
            $mediaPaths = Message::query()
                ->whereIn('conversation_id', $conversationIds)
                ->whereNotNull('media_path')
                ->pluck('media_path')
                ->all();
            Message::query()->whereIn('conversation_id', $conversationIds)->delete();

            return $mediaPaths;
        });

        $this->deleteUnreferencedMessageMedia($mediaPaths);
        Flux::toast(variant: 'success', text: 'All SMS message history cleared.');
    }

    /** @param array<int, string> $mediaPaths */
    private function deleteUnreferencedMessageMedia(array $mediaPaths): void
    {
        $disk = Storage::disk('local');
        foreach (array_unique($mediaPaths) as $path) {
            if (! Message::query()->where('media_path', $path)->exists()) {
                $disk->delete($path);
            }
        }
    }

    public function formatStorageBytes(int $bytes): string
    {
        if ($bytes < 1024) {
            return $bytes . ' B';
        }

        $units = ['KB', 'MB', 'GB', 'TB'];
        $size = (float) $bytes;
        foreach ($units as $unit) {
            $size /= 1024;
            if ($size < 1024 || $unit === 'TB') {
                return number_format($size, 1) . ' ' . $unit;
            }
        }

        return number_format($size, 1) . ' TB';
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
        $this->showSettings = false;
        $this->showContactForm = false;
        $this->showWebContactNotice = false;
        $this->showFavoritePicker = false;
        $this->showDialpad = false;
        $this->showCallScreen = false;
        $this->showContactProfile = false;
        $this->showStatusCreator = false;
        $this->showChannelComposer = false;
        $this->search = '';
    }

    public function dismissSystemNotification(string $key): void
    {
        $isKnownNotice = in_array($key, [
            'maintenance-2026-10-18',
            'policy-update-2026-10',
        ], true) || preg_match('/^subscription-expiring-\d+$/', $key) === 1;
        if (! $isKnownNotice) {
            return;
        }

        $this->dismissedSystemNotifications = array_values(array_unique([
            ...$this->dismissedSystemNotifications,
            $key,
        ]));
        session()->put(
            $this->dismissedSystemNotificationsSessionKey(),
            $this->dismissedSystemNotifications,
        );
    }

    /** @return array<int, array{key: string, icon: string, heading: string, text: string, renewable: bool}> */
    public function getSystemNotificationsProperty(): array
    {
        $notifications = [];
        $dismissed = $this->dismissedSystemNotifications;
        $maintenanceEndsAt = \Illuminate\Support\Carbon::parse('2026-10-18 05:00:00', 'UTC');

        if (now('UTC')->lt($maintenanceEndsAt)) {
            $notifications[] = [
                'key' => 'maintenance-2026-10-18',
                'icon' => 'clock',
                'heading' => 'Upcoming maintenance',
                'text' => 'Our servers will be undergoing scheduled maintenance this Sunday from 2 AM - 5 AM UTC. Some services may be temporarily unavailable.',
                'renewable' => false,
            ];
        }

        $userId = Auth::id();
        if ($userId !== null) {
            $expiringSubscription = Subscription::query()
                ->with('plan')
                ->where('user_id', $userId)
                ->where('status', 'active')
                ->whereNotNull('ends_at')
                ->whereBetween('ends_at', [now(), now()->addDays(7)])
                ->orderBy('ends_at')
                ->first();

            if ($expiringSubscription !== null) {
                $renewalIsScheduled = Subscription::query()
                    ->where('user_id', $userId)
                    ->where('status', 'active')
                    ->where('activated_at', '>', now())
                    ->where('activated_at', '<=', $expiringSubscription->ends_at)
                    ->exists();
                if (! $renewalIsScheduled) {
                    $daysRemaining = max(
                        1,
                        (int) ceil(now()->diffInSeconds($expiringSubscription->ends_at) / 86400),
                    );
                    $notifications[] = [
                        'key' => 'subscription-expiring-' . $expiringSubscription->id,
                        'icon' => 'clock',
                        'heading' => 'Subscription expiring soon',
                        'text' => "Your {$expiringSubscription->plan->name} plan expires in {$daysRemaining} days. Renew now to keep your subscription features.",
                        'renewable' => true,
                    ];
                }
            }
        }

        $notifications[] = [
            'key' => 'policy-update-2026-10',
            'icon' => 'newspaper',
            'heading' => 'Policy update',
            'text' => 'We\'ve updated our Terms of Service and Privacy Policy. Please review them to stay informed.',
            'renewable' => false,
        ];

        return collect($notifications)
            ->reject(fn(array $notification): bool => in_array($notification['key'], $dismissed, true))
            ->values()
            ->all();
    }

    private function dismissedSystemNotificationsSessionKey(): string
    {
        return 'airtext.dismissed-system-notifications.' . (Auth::id() ?? 'guest');
    }

    private function publicStorageUrl(?string $path): string
    {
        if ($path === null || $path === '') {
            return '';
        }

        /** @var \Illuminate\Filesystem\FilesystemAdapter $disk */
        $disk = Storage::disk('public');

        return $disk->url($path);
    }

    public function mount(): void
    {
        $this->dismissedSystemNotifications = session()->get(
            $this->dismissedSystemNotificationsSessionKey(),
            [],
        );

        $user = Auth::user();
        if ($user instanceof User) {
            $this->displayName = $user->name ?: $this->displayName;
            $this->phoneNumber = $user->phone_number ?: $this->phoneNumber;
            $this->lastSeenVisibility = $user->last_seen_visibility ?: $this->lastSeenVisibility;
            $this->profilePictureVisibility = $user->profile_picture_visibility ?: $this->profilePictureVisibility;
            $this->statusVisibility = $user->status_visibility ?: $this->statusVisibility;
            $this->profilePhotoUrl = $this->publicStorageUrl($user->profile_photo_path);

            $storageSettings = $user->storage_settings ?? [];
            $this->useLessDataForCalls = (bool) ($storageSettings['use_less_data_for_calls'] ?? $this->useLessDataForCalls);
            $this->uploadQuality = in_array($storageSettings['upload_quality'] ?? null, ['standard', 'hd'], true)
                ? $storageSettings['upload_quality']
                : $this->uploadQuality;
            $this->autoDownloadQuality = in_array($storageSettings['auto_download_quality'] ?? null, ['auto', 'high'], true)
                ? $storageSettings['auto_download_quality']
                : $this->autoDownloadQuality;
            $this->mobileDataDownloads = in_array($storageSettings['mobile_data_downloads'] ?? null, ['none', 'photos', 'all'], true)
                ? $storageSettings['mobile_data_downloads']
                : $this->mobileDataDownloads;
            $this->wifiDownloads = in_array($storageSettings['wifi_downloads'] ?? null, ['none', 'photos', 'all'], true)
                ? $storageSettings['wifi_downloads']
                : $this->wifiDownloads;
            $this->roamingDownloads = in_array($storageSettings['roaming_downloads'] ?? null, ['none', 'photos', 'all'], true)
                ? $storageSettings['roaming_downloads']
                : $this->roamingDownloads;
        }

        $this->shopProducts = [
            [
                'id' => 'tourism-sms-bot',
                'category' => 'bots',
                'icon' => 'chat-bubble-left-right',
                'eyebrow' => 'AI assistant',
                'name' => 'Tourism SMS Bot',
                'description' => 'Autonomous trip confirmations, promos, and FAQ replies for tour operators and agencies.',
                'price' => 45000,
                'price_label' => 'TZS 45,000',
                'action' => 'Install',
            ],
            [
                'id' => 'gateway-recovery-suite',
                'category' => 'gateways',
                'icon' => 'signal',
                'eyebrow' => 'Operations',
                'name' => 'Gateway Recovery Suite',
                'description' => 'Retry logic, routing fallbacks, and delivery alerts to keep your SMS flow resilient.',
                'price' => 120000,
                'price_label' => 'TZS 120,000',
                'action' => 'Deploy',
            ],
            [
                'id' => 'lead-capture-templates',
                'category' => 'templates',
                'icon' => 'document-text',
                'eyebrow' => 'Campaigns',
                'name' => 'Lead Capture Templates',
                'description' => 'Ready-made response flows for property shows, sales inquiries, and follow-up sequences.',
                'price' => 18000,
                'price_label' => 'TZS 18,000',
                'action' => 'Use template',
            ],
        ];

        $this->syncInstalledShopItems();
    }

    public function filterShop(string $category): void
    {
        $this->shopCategory = $category;
    }

    public function showShopSection(string $section): void
    {
        if (! in_array($section, ['browse', 'subscriptions'], true)) {
            return;
        }

        $this->shopSection = $section;
        $this->showSubscriptionCheckout = false;
    }

    public function openSubscriptionPlans(): void
    {
        $this->showPanel('shop');
        $this->shopSection = 'subscriptions';
    }

    public function chooseSubscriptionPlan(string $planCode): void
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in to activate a subscription.');

            return;
        }

        $plan = SubscriptionPlan::query()
            ->where('code', $planCode)
            ->where('is_active', true)
            ->first();
        if ($plan === null) {
            Flux::toast(variant: 'danger', text: 'This subscription plan is unavailable.');

            return;
        }

        if ($this->pendingSubscription !== null) {
            Flux::toast(variant: 'warning', text: 'A subscription payment is already awaiting confirmation.');
            return;
        }

        if ($plan->price_tzs === 0) {
            if ($this->currentSubscription !== null) {
                Flux::toast(variant: 'warning', text: 'You already have an active subscription.');

                return;
            }

            $user->subscriptions()->create([
                'subscription_plan_id' => $plan->id,
                'status' => 'active',
                'activated_at' => now(),
            ]);
            $this->shopSection = 'subscriptions';
            Flux::toast(variant: 'success', text: 'Free Starter is now active.');

            return;
        }

        $this->selectedSubscriptionPlanCode = $plan->code;
        $this->subscriptionPhoneNumber = $user->phone_number ?? '';
        $this->showSubscriptionCheckout = true;
    }

    public function startSubscriptionCheckout(): void
    {
        $validated = $this->validate([
            'selectedSubscriptionPlanCode' => ['required', 'exists:subscription_plans,code'],
            'subscriptionPhoneNumber' => ['required', 'regex:/^\\+[1-9][0-9]{7,14}$/'],
            'subscriptionGateway' => ['required', 'in:azampay,selcom'],
        ]);
        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in before starting checkout.');

            return;
        }

        $plan = SubscriptionPlan::query()
            ->where('code', $validated['selectedSubscriptionPlanCode'])
            ->where('is_active', true)
            ->firstOrFail();

        try {
            app(ShopSubscriptionCheckout::class)->start(
                $user,
                $plan,
                $validated['subscriptionPhoneNumber'],
                $validated['subscriptionGateway'],
            );
        } catch (\RuntimeException $exception) {
            Flux::toast(variant: 'danger', text: $exception->getMessage());

            return;
        }

        $this->showSubscriptionCheckout = false;
        $this->shopSection = 'subscriptions';
        Flux::toast(variant: 'success', text: 'Payment request sent. Your plan will activate after payment is confirmed.');
    }

    public function cancelSubscriptionCheckout(): void
    {
        $this->showSubscriptionCheckout = false;
        $this->selectedSubscriptionPlanCode = null;
        $this->resetValidation();
    }

    public function topUpCredits(): void
    {
        Flux::toast(variant: 'danger', text: 'Wallet top-ups are unavailable until a verified payment provider is configured.');
    }

    public function purchaseShopProduct(string $productId): void
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in to install a marketplace product.');

            return;
        }

        $product = collect($this->shopProducts)->firstWhere('id', $productId);
        if ($product === null) {
            Flux::toast(variant: 'danger', text: 'This marketplace product is not available.');

            return;
        }

        if ($product['price'] > 0 && ! $this->shopCheckoutConfigured()) {
            Flux::toast(variant: 'danger', text: 'No purchase was made. A verified payment provider is not configured.');

            return;
        }

        $transaction = ShopTransaction::query()->create([
            'user_id' => $user->id,
            'reference_id' => 'AIR_' . strtoupper(Str::random(12)),
            'package_id' => $product['id'],
            'amount' => $product['price'],
            'currency' => 'TZS',
            'payment_gateway' => $this->shopCheckoutConfigured() ? 'configured' : 'demo',
            'phone_number' => $user->phone_number ?? '',
            'status' => 'paid',
        ]);

        if ($product['category'] === 'bots') {
            UserInstalledBot::withoutEvents(function () use ($user, $product): void {
                $user->installedBots()->updateOrCreate(
                    ['bot_identifier' => $product['id']],
                    [
                        'status' => 'active',
                        'installed_at' => now(),
                        'expires_at' => null,
                    ],
                );
            });
        }

        $this->syncInstalledShopItems();
        Flux::toast(variant: 'success', text: $product['name'] . ' is ready to use.');
    }

    private function shopCheckoutConfigured(): bool
    {
        $azampay = config('services.azampay');
        $selcom = config('services.selcom');

        return (is_array($azampay) && (
            ! empty($azampay['token']) || ! empty($azampay['base_url'])
        )) || (is_array($selcom) && (
            ! empty($selcom['api_key']) || ! empty($selcom['api_secret']) || ! empty($selcom['vendor']) || ! empty($selcom['base_url'])
        ));
    }

    private function syncInstalledShopItems(): void
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            $this->installedShopItems = [];

            return;
        }

        $this->installedShopItems = $user->installedBots()
            ->where('status', 'active')
            ->get()
            ->map(function (UserInstalledBot $bot): ?array {
                $product = collect($this->shopProducts)->firstWhere('id', $bot->bot_identifier);
                if ($product === null) {
                    return null;
                }

                return [
                    'icon' => $product['icon'],
                    'name' => $product['name'],
                    'type' => 'AI bot',
                    'meta' => $bot->installed_at?->diffForHumans() ?? 'Active',
                    'status' => 'Active',
                ];
            })
            ->filter()
            ->values()
            ->all();
    }

    public function openContactForm(): void
    {
        $this->showWebContactNotice = false;
        $this->resetValidation();
        $this->reset(['contactFirstName', 'contactLastName', 'contactPhone']);
        $this->showContactForm = true;
    }

    public function prepareContactForm(): void
    {
        $this->openContactForm();
    }

    public function closeWebContactNotice(): void
    {
        $this->showWebContactNotice = false;
    }

    /** @return array<int, ContactRow> */
    public function getRegisteredContactsProperty(): array
    {
        return collect($this->filteredContacts)->filter(fn(array $contact): bool => $contact['is_registered'])->values()->all();
    }

    /** @return array<int, array{name: string, phone_number: string, initials: string}> */
    public function getInviteContactsProperty(): array
    {
        $registeredNumbers = Contact::query()->pluck('phone_number')->map(fn(string $number): string => preg_replace('/\s+/', '', $number))->all();

        return collect($this->deviceContacts)
            ->filter(function (array $contact) use ($registeredNumbers): bool {
                $number = preg_replace('/\s+/', '', $contact['phone_number']);

                return ! in_array($number, $registeredNumbers, true)
                    && ($this->search === '' || str_contains(strtolower($contact['name'] . ' ' . $contact['phone_number']), strtolower($this->search)));
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

        $name = trim($validated['contactFirstName'] . ' ' . $validated['contactLastName']);
        $contact = Contact::updateOrCreate(['phone_number' => $validated['contactPhone']], [
            'name' => $name,
            'status_bio' => 'SMS contact',
            'payload_prefix' => $this->contactPayloadPrefix,
            'is_registered' => false,
        ]);

        $conversation = Conversation::firstOrCreate(
            ['phone_number' => $validated['contactPhone']],
            ['name' => $name],
        );

        if (! collect($this->conversations)->contains('id', $conversation->id)) {
            $this->conversations[] = [
                'id' => $conversation->id,
                'name' => $name,
                'initials' => strtoupper(substr($name, 0, 1) . substr(strstr($name, ' ') ?: $name, 1, 1)),
                'tone' => 'bg-stone-400',
                'time' => 'New',
                'preview' => 'New SMS conversation',
                'status' => 'SMS contact',
                'unread' => 0,
                'messages' => [],
            ];
        }

        $this->activeConversationId = $conversation->id;
        $this->showConversation = true;
        $this->showContactForm = false;
        $this->leftPanel = 'chats';
    }

    public function uploadProfilePhoto(): void
    {
        $this->validate([
            'profilePhoto' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in before uploading a profile photo.');

            return;
        }

        $oldPath = $user->profile_photo_path;
        $newPath = $this->profilePhoto->store('profile-photos/' . $user->id, 'public');

        $user->forceFill(['profile_photo_path' => $newPath])->save();
        if ($oldPath !== null && $oldPath !== $newPath) {
            Storage::disk('public')->delete($oldPath);
        }

        $this->profilePhotoUrl = $this->publicStorageUrl($newPath);
        $this->profilePhoto = null;

        Flux::toast(variant: 'success', text: 'Your profile photo was updated.');
    }

    public function removeProfilePhoto(): void
    {
        $user = Auth::user();
        if (! $user instanceof User) {
            return;
        }

        if ($user->profile_photo_path !== null) {
            Storage::disk('public')->delete($user->profile_photo_path);
            $user->forceFill(['profile_photo_path' => null])->save();
        }

        $this->profilePhotoUrl = '';
        Flux::toast(variant: 'success', text: 'Your profile photo was removed.');
    }

    public function savePrivacySettings(): void
    {
        $validated = $this->validate([
            'lastSeenVisibility' => ['required', 'in:Everyone,My contacts,My contacts except...,Nobody'],
            'profilePictureVisibility' => ['required', 'in:Everyone,My contacts,Nobody'],
            'statusVisibility' => ['required', 'in:Everyone,My contacts,Nobody'],
        ]);

        $user = Auth::user();
        if (! $user instanceof User) {
            Flux::toast(variant: 'danger', text: 'Sign in to change your privacy settings.');

            return;
        }

        $user->forceFill([
            'last_seen_visibility' => $validated['lastSeenVisibility'],
            'profile_picture_visibility' => $validated['profilePictureVisibility'],
            'status_visibility' => $validated['statusVisibility'],
        ])->save();

        Flux::toast(variant: 'success', text: 'Your privacy settings were updated.');
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
        $this->showStorageDetails = false;
        $this->showNetworkDetails = false;
        $this->showProxyDetails = false;
    }

    public function sendMessage(): void
    {
        if ($this->activeConversationPreferences['blocked']) {
            return;
        }

        $body = trim($this->messageDraft);

        if ($this->messageAttachment !== null) {
            $this->sendMessageAttachment($body);

            return;
        }

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
