<nav class="shop-filters" aria-label="Shop categories">
    @foreach(['all' => 'All', 'bots' => 'SMS Bots', 'gateways' => 'Gateways', 'templates' => 'Templates'] as $category => $label)
        <button type="button" wire:click="filterShop('{{ $category }}')" class="shop-filter {{ $shopCategory === $category ? 'is-active' : '' }}" aria-pressed="{{ $shopCategory === $category ? 'true' : 'false' }}">{{ $label }}</button>
    @endforeach
</nav>
