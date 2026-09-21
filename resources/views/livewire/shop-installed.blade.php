<section class="shop-installed-section" aria-labelledby="installed-services-heading">
    <div class="shop-section-heading"><div><p class="shop-kicker">YOUR WORKSPACE</p><flux:heading id="installed-services-heading" size="lg">Installed extensions & services</flux:heading></div><flux:badge color="green">{{ count($installedShopItems) }} active</flux:badge></div>
    <div class="shop-installed-list">
        @foreach($installedShopItems as $item)
            <article class="shop-installed-item">
                <span class="shop-installed-icon"><flux:icon name="{{ $item['icon'] }}" variant="outline" /></span>
                <div><strong>{{ $item['name'] }}</strong><small>{{ $item['type'] }} · {{ $item['meta'] }}</small></div>
                <span class="shop-active-status"><i></i>{{ $item['status'] }}</span>
                <flux:button variant="ghost" icon="ellipsis-vertical" square aria-label="Options for {{ $item['name'] }}" />
            </article>
        @endforeach
    </div>
</section>
