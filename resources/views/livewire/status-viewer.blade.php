@if($this->activeStatus)
@php($status = $this->activeStatus)
<section class="status-viewer" aria-label="Status viewer">
    <div class="status-progress-bars" aria-hidden="true">
        @foreach($this->statusUpdates as $story)
        <span class="{{ $loop->index <= $activeStatusIndex ? 'is-complete' : '' }}"></span>
        @endforeach
    </div>
    <header class="status-viewer-header">
        <div class="status-viewer-person">
            <flux:avatar initials="{{ $status['author_initials'] }}" color="zinc" size="sm" />
            <div><strong>{{ $status['author_name'] }}</strong><small>{{ $status['created_at_label'] }}</small></div>
        </div>
        <div class="header-actions">
            <flux:button wire:click="toggleStatusPlayback" variant="ghost" icon="{{ $statusPaused ? 'play' : 'pause' }}" square aria-label="{{ $statusPaused ? 'Play status' : 'Pause status' }}" />
            <flux:button wire:click="toggleStatusMute" variant="ghost" icon="{{ $statusMuted ? 'speaker-x-mark' : 'speaker-wave' }}" square aria-label="{{ $statusMuted ? 'Unmute status' : 'Mute status' }}" />
            <flux:button wire:click="closeStatusViewer" variant="ghost" icon="x-mark" square aria-label="Close status viewer" />
        </div>
    </header>
    <div class="status-display-canvas" style="--status-background: {{ $status['background'] }}">
        @if($status['media_type'] === 'media' && $status['media_path'])
        @if(str_ends_with(strtolower($status['media_path']), '.mp4') || str_ends_with(strtolower($status['media_path']), '.mov'))
        <video src="{{ asset('storage/'.$status['media_path']) }}" autoplay muted="{{ $statusMuted ? 'true' : 'false' }}" controls></video>
        @else
        <img src="{{ asset('storage/'.$status['media_path']) }}" alt="Status from {{ $status['author_name'] }}">
        @endif
        @else
        <p class="status-text-payload status-font-{{ $status['font'] }}">{{ $status['body'] }}</p>
        @endif
        @if($status['caption'])<p class="status-caption">{{ $status['caption'] }}</p>@endif
        <button type="button" wire:click="previousStatus" class="status-nav status-nav-prev" aria-label="Previous status"><flux:icon.chevron-left /></button>
        <button type="button" wire:click="nextStatus" class="status-nav status-nav-next" aria-label="Next status"><flux:icon.chevron-right /></button>
    </div>
    <div class="status-utility-row">
        @if($status['view_once'])
        <span class="status-chip">View once</span>
        @endif
        @if($status['screenshot_protected'])
        <span class="status-chip">Screenshot protected</span>
        @endif
        <span class="status-chip">{{ (int) ($status['viewers_count'] ?? 0) }} viewer{{ (int) ($status['viewers_count'] ?? 0) === 1 ? '' : 's' }}</span>
    </div>
    @if($status['author_name'] !== $displayName)
    <div class="status-action-row">
        <button type="button" wire:click="toggleStatusLike" class="status-action-button {{ $statusLiked ? 'is-liked' : '' }}">
            {{ $statusLiked ? 'Liked' : 'Like' }}
        </button>
    </div>
    <form wire:submit="sendStatusReply" class="status-reply-bar">
        <flux:input wire:model="statusReply" placeholder="Type a reply..." aria-label="Reply to status" />
        <flux:button type="submit" variant="primary" icon="paper-airplane" aria-label="Send reply" />
    </form>
    @endif
</section>
@else
<section class="status-empty-viewer" aria-label="Status updates">
    <flux:icon.globe-alt variant="outline" />
    <flux:heading size="lg">Status updates</flux:heading>
    <flux:text>Share a moment or select an update from the sidebar.</flux:text>
    <flux:button wire:click="openStatusCreator('text')" variant="primary" icon="plus">Create status</flux:button>
</section>
@endif
