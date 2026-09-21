<header class="shop-header">
    <div>
        <p class="shop-kicker">AIRTEXT MARKETPLACE</p>
        <flux:heading size="xl">Shop & Marketplace</flux:heading>
        <flux:text>Tools and services for reliable business messaging.</flux:text>
    </div>
    <div class="shop-wallet">
        <span class="shop-wallet-icon"><flux:icon.wallet variant="outline" /></span>
        <div><small>Available credits</small><strong>{{ number_format($shopBalance) }} SMS</strong></div>
        <flux:button wire:click="topUpCredits" variant="primary" icon="plus">Top up credits</flux:button>
    </div>
</header>
<div class="shop-search-row">
    <flux:input wire:model.live.debounce.250ms="shopSearch" icon="magnifying-glass" placeholder="Search bots, services, extensions..." aria-label="Search shop" />
</div>
