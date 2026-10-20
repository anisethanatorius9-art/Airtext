<section class="shop-products-section" aria-labelledby="featured-products-heading">
    <div class="shop-section-heading">
        <div>
            <p class="shop-kicker">CURATED FOR YOUR WORKFLOW</p>
            <flux:heading id="featured-products-heading" size="lg">Featured products & services</flux:heading>
        </div>
        <flux:text>{{ count($this->filteredShopProducts) }} available</flux:text>
    </div>
    <div class="shop-product-grid">
        @forelse($this->filteredShopProducts as $product)
        @php $isInstalled = (bool) ($product['is_installed'] ?? false); @endphp
        <article wire:key="shop-product-{{ $product['id'] }}" class="shop-product-card">
            <div class="shop-product-icon">
                <flux:icon name="{{ $product['icon'] }}" variant="outline" />
            </div>
            <p class="shop-product-eyebrow">{{ $product['eyebrow'] }}</p>
            <flux:heading size="lg">{{ $product['name'] }}</flux:heading>
            <flux:text>{{ $product['description'] }}</flux:text>
            <div class="shop-product-footer"><strong>{{ $product['price_label'] }}</strong>
                @if($isInstalled)
                    <flux:button type="button" variant="ghost" size="sm" icon="check" disabled>{{ $product['action'] }}</flux:button>
                @else
                    <flux:button wire:click="purchaseShopProduct('{{ $product['id'] }}')" variant="primary" size="sm" icon="arrow-down-tray">{{ $product['action'] }}</flux:button>
                @endif
            </div>
        </article>
        @empty
        <div class="shop-empty-state"><flux:icon.magnifying-glass variant="outline" />
            <flux:heading size="lg">{{ filled($shopSearch) ? 'No products match your search' : 'No products found' }}</flux:heading>
            <flux:text>{{ filled($shopSearch) ? 'Try a different keyword or switch back to the full catalog.' : 'Try another search or category.' }}</flux:text>
        </div>
        @endforelse
    </div>
</section>
