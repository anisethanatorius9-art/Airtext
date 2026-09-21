@if($showStatusCreator)
    <div class="status-modal-backdrop">
        <section class="status-creator" role="dialog" aria-modal="true" aria-labelledby="status-creator-title">
            <header class="status-creator-header">
                <flux:heading id="status-creator-title" size="lg">Create status</flux:heading>
                <flux:button wire:click="closeStatusCreator" variant="ghost" icon="x-mark" square aria-label="Close status creator" />
            </header>
            <div class="status-mode-switcher" role="tablist" aria-label="Status type">
                <button type="button" wire:click="$set('statusMode', 'text')" class="{{ $statusMode === 'text' ? 'is-active' : '' }}" role="tab" aria-selected="{{ $statusMode === 'text' ? 'true' : 'false' }}"><flux:icon.paint-brush variant="outline" /> Text status</button>
                <button type="button" wire:click="$set('statusMode', 'media')" class="{{ $statusMode === 'media' ? 'is-active' : '' }}" role="tab" aria-selected="{{ $statusMode === 'media' ? 'true' : 'false' }}"><flux:icon.photo variant="outline" /> Photo / video</button>
            </div>
            <form wire:submit="publishStatus" class="status-creator-form">
                @if($statusMode === 'text')
                    <div class="status-text-editor" style="--status-background: {{ $statusBackground }}">
                        <textarea wire:model="statusText" class="status-editor-textarea status-font-{{ $statusFont }}" placeholder="Type a status" aria-label="Status text"></textarea>
                    </div>
                    <div class="status-editor-tools">
                        <label class="status-color-picker"><span>Background</span><input type="color" wire:model.live="statusBackground" aria-label="Status background color"></label>
                        <flux:select wire:model="statusFont" aria-label="Status font"><option value="sans">Sans</option><option value="serif">Serif</option><option value="mono">Mono</option></flux:select>
                    </div>
                @else
                    <label class="status-upload-area">
                        <flux:icon.cloud-arrow-up variant="outline" />
                        <strong>Choose photo or video</strong>
                        <small>JPG, PNG, WEBP, MP4 or MOV up to 50 MB</small>
                        <flux:input type="file" wire:model="statusMedia" accept="image/*,video/*" class="sr-only" />
                    </label>
                    @if($statusMedia)
                        <div class="status-upload-preview"><flux:text>{{ $statusMedia->getClientOriginalName() }}</flux:text></div>
                    @endif
                @endif
                <flux:input wire:model="statusCaption" placeholder="Add a caption..." aria-label="Status caption" />
                <flux:select wire:model="statusPrivacy" aria-label="Status privacy"><option value="Contacts">Status privacy (Contacts)</option><option value="Everyone">Status privacy (Everyone)</option></flux:select>
                @error('statusText')<flux:error>{{ $message }}</flux:error>@enderror
                @error('statusMedia')<flux:error>{{ $message }}</flux:error>@enderror
                @error('statusCaption')<flux:error>{{ $message }}</flux:error>@enderror
                <flux:button type="submit" variant="primary" icon="paper-airplane">Post status</flux:button>
            </form>
        </section>
    </div>
@endif
