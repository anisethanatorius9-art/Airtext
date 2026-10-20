<section class="subscription-page" aria-labelledby="subscription-page-heading">
    <header class="subscription-page-header">
        <div>
            <p class="shop-kicker">AIRTEXT PLANS</p>
            <flux:heading id="subscription-page-heading" size="xl">Choose your plan</flux:heading>
            <flux:text>Messaging stays available on Free Starter. Upgrade when you need more tools.</flux:text>
        </div>
    </header>

    @if($this->currentSubscription)
    <flux:callout icon="check-circle" variant="secondary" class="subscription-state-callout">
        <flux:callout.heading>Subscription active · {{ $this->currentSubscription->plan->name }}</flux:callout.heading>
        <flux:callout.text>
            @if($this->currentSubscription->ends_at)
            Your plan is active until {{ $this->currentSubscription->ends_at->format('M j, Y') }}.
            @else
            Your Free Starter plan is active with no expiry date.
            @endif
        </flux:callout.text>
    </flux:callout>
    @elseif($this->pendingSubscription)
    <flux:callout icon="clock" variant="secondary" class="subscription-state-callout">
        <flux:callout.heading>Payment awaiting confirmation · {{ $this->pendingSubscription->plan->name }}</flux:callout.heading>
        <flux:callout.text>Your plan will activate after the payment provider confirms the transaction.</flux:callout.text>
    </flux:callout>
    @endif

    @if($this->upcomingSubscription)
    <flux:callout icon="calendar-days" variant="secondary" class="subscription-state-callout">
        <flux:callout.heading>Renewal scheduled · {{ $this->upcomingSubscription->plan->name }}</flux:callout.heading>
        <flux:callout.text>Your next subscription period starts {{ $this->upcomingSubscription->activated_at->format('M j, Y') }}.</flux:callout.text>
    </flux:callout>
    @endif

    <div class="subscription-plan-grid">
        @forelse($this->subscriptionPlans as $plan)
        @php($isCurrentPlan = $this->currentSubscription?->subscription_plan_id === $plan['id'] ?? false)
        <article wire:key="subscription-plan-{{ $plan['code'] }}" class="subscription-plan-card {{ str_starts_with($plan['code'], 'biz_') ? 'is-business' : '' }}">
            <div class="subscription-plan-topline">
                <span class="subscription-plan-mark"><flux:icon name="{{ str_starts_with($plan['code'], 'biz_') ? 'building-office-2' : 'sparkles' }}" variant="outline" /></span>
                @if($isCurrentPlan)<flux:badge color="green">Current plan</flux:badge>@endif
            </div>
            <flux:heading size="lg">{{ $plan['name'] }}</flux:heading>
            <flux:text>{{ $plan['description'] }}</flux:text>
            <p class="subscription-plan-price">
                <strong>{{ $plan['price_tzs'] === 0 ? 'Free' : 'TZS '.number_format($plan['price_tzs']) }}</strong>
                <span>{{ $plan['duration_days'] ? ' / '.$plan['duration_days'].' days' : ' / forever' }}</span>
            </p>
            <ul class="subscription-plan-features">
                @foreach($plan['features'] as $feature)
                <li><flux:icon.check variant="outline" />{{ $feature }}</li>
                @endforeach
            </ul>
            @if($isCurrentPlan && $plan['price_tzs'] === 0)
            <flux:button variant="ghost" class="subscription-plan-action" disabled>Current plan</flux:button>
            @else
            <flux:button wire:click="chooseSubscriptionPlan('{{ $plan['code'] }}')" variant="{{ $plan['price_tzs'] === 0 ? 'ghost' : 'primary' }}" class="subscription-plan-action">
                {{ $isCurrentPlan ? 'Renew plan' : ($plan['price_tzs'] === 0 ? 'Start for free' : 'Choose plan') }}
            </flux:button>
            @endif
        </article>
        @empty
        <p class="shop-empty-state">Subscription plans are not available right now.</p>
        @endforelse
    </div>

    <flux:text class="subscription-payment-note">Paid plans remain pending until the payment provider confirms your payment. Prices are charged in Tanzanian shillings.</flux:text>
</section>

@if($showSubscriptionCheckout)
@php($selectedPlan = collect($this->subscriptionPlans)->firstWhere('code', $selectedSubscriptionPlanCode))
<div class="subscription-checkout-backdrop">
    <section class="subscription-checkout-dialog" role="dialog" aria-modal="true" aria-labelledby="subscription-checkout-title">
        <header class="subscription-checkout-header">
            <div>
                <p class="shop-kicker">SECURE CHECKOUT</p>
                <flux:heading id="subscription-checkout-title" size="lg">{{ $selectedPlan['name'] ?? 'Subscription checkout' }}</flux:heading>
            </div>
            <flux:button wire:click="cancelSubscriptionCheckout" variant="ghost" icon="x-mark" square aria-label="Close checkout" />
        </header>
        @if($selectedPlan)
        <p class="subscription-checkout-total">TZS {{ number_format($selectedPlan['price_tzs']) }} <span>· {{ $selectedPlan['duration_days'] }} days</span></p>
        @endif
        <form wire:submit="startSubscriptionCheckout" class="subscription-checkout-form">
            <flux:field>
                <flux:label>Mobile money phone number</flux:label>
                <flux:input wire:model="subscriptionPhoneNumber" type="tel" placeholder="+255712345678" />
                @error('subscriptionPhoneNumber')<flux:error>{{ $message }}</flux:error>@enderror
            </flux:field>
            <flux:field>
                <flux:label>Payment provider</flux:label>
                <select wire:model="subscriptionGateway" class="settings-select">
                    <option value="azampay">AzamPay</option>
                    <option value="selcom">Selcom</option>
                </select>
                @error('subscriptionGateway')<flux:error>{{ $message }}</flux:error>@enderror
            </flux:field>
            <div class="subscription-checkout-actions">
                <flux:button type="button" wire:click="cancelSubscriptionCheckout" variant="ghost">Cancel</flux:button>
                <flux:button type="submit" variant="primary" icon="lock-closed">Request payment</flux:button>
            </div>
        </form>
    </section>
</div>
@endif
