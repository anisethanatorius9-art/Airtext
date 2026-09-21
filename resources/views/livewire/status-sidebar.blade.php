<header class="chats-header status-sidebar-header">
    <flux:heading size="xl">Status</flux:heading>
    <div class="header-actions">
        <flux:button wire:click="openStatusCreator('text')" variant="ghost" icon="plus" square aria-label="Create status" />
        <flux:dropdown position="bottom" align="end">
            <flux:button variant="ghost" icon="ellipsis-vertical" square aria-label="Status options" />
            <flux:menu>
                <flux:menu.item wire:click="openStatusCreator('media')" icon="photo">Upload photo or video</flux:menu.item>
                <flux:menu.item icon="shield-check">Status privacy</flux:menu.item>
            </flux:menu>
        </flux:dropdown>
    </div>
</header>

<div class="status-sidebar-content">
    <button type="button" wire:click="openStatusCreator('text')" class="my-status-card">
        <span class="my-status-avatar"><flux:avatar initials="A" color="green" size="md" /><b>+</b></span>
        <span><strong>My status</strong><small>Click to add status update</small><small>Disappears after 24 hours</small></span>
    </button>

    <section class="status-section" aria-labelledby="recent-statuses-heading">
        <h2 id="recent-statuses-heading" class="status-section-label">Recent updates</h2>
        @forelse($this->recentStatuses as $status)
            <button type="button" wire:key="recent-status-{{ $status['id'] }}" wire:click="openStatus({{ $status['id'] }})" class="status-list-item">
                <span class="status-ring is-unseen"><flux:avatar initials="{{ $status['author_initials'] }}" color="zinc" size="md" /></span>
                <span><strong>{{ $status['author_name'] }}</strong><small>{{ $status['created_at_label'] }}</small></span>
            </button>
        @empty
            <p class="status-empty">No recent updates.</p>
        @endforelse
    </section>

    <section class="status-section" aria-labelledby="viewed-statuses-heading">
        <h2 id="viewed-statuses-heading" class="status-section-label">Viewed updates</h2>
        @forelse($this->viewedStatuses as $status)
            <button type="button" wire:key="viewed-status-{{ $status['id'] }}" wire:click="openStatus({{ $status['id'] }})" class="status-list-item">
                <span class="status-ring"><flux:avatar initials="{{ $status['author_initials'] }}" color="zinc" size="md" /></span>
                <span><strong>{{ $status['author_name'] }}</strong><small>{{ $status['created_at_label'] }}</small></span>
            </button>
        @empty
            <p class="status-empty">Viewed updates will appear here.</p>
        @endforelse
    </section>
</div>
