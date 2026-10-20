<section class="shop-page" aria-label="AirText Shop and Marketplace">
    @include('livewire.shop-header')
    <nav class="shop-section-tabs" aria-label="Shop sections">
        <button type="button" wire:click="showShopSection('browse')" class="shop-section-tab {{ $shopSection === 'browse' ? 'is-active' : '' }}" aria-pressed="{{ $shopSection === 'browse' ? 'true' : 'false' }}">Browse</button>
        <button type="button" wire:click="showShopSection('subscriptions')" class="shop-section-tab {{ $shopSection === 'subscriptions' ? 'is-active' : '' }}" aria-pressed="{{ $shopSection === 'subscriptions' ? 'true' : 'false' }}">Subscriptions</button>
    </nav>
    @if($shopSection === 'subscriptions')
    @include('livewire.shop-subscriptions')
    @else
    @include('livewire.shop-filters')
    @include('livewire.shop-products')
    @include('livewire.shop-installed')
    @endif
</section>
