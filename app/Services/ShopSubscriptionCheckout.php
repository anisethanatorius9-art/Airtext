<?php

namespace App\Services;

use App\Models\ShopTransaction;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Carbon;
use RuntimeException;

class ShopSubscriptionCheckout
{
    public function start(User $user, SubscriptionPlan $plan, string $phoneNumber, string $gateway): ShopTransaction
    {
        if ($user->subscriptions()->where('status', 'pending_payment')->exists()) {
            throw new RuntimeException('A subscription payment is already awaiting confirmation.');
        }

        $gatewayConfig = config('services.'.$gateway);
        $isSelcom = $gateway === 'selcom';
        $credentialsConfigured = $isSelcom
            ? ! empty($gatewayConfig['api_key']) && ! empty($gatewayConfig['api_secret']) && ! empty($gatewayConfig['vendor'])
            : ! empty($gatewayConfig['token']);
        if (empty($gatewayConfig['base_url']) || ! $credentialsConfigured) {
            throw new RuntimeException('Payment provider is not configured. No payment was started.');
        }

        $transaction = ShopTransaction::query()->create([
            'user_id' => $user->id,
            'reference_id' => 'AIR_'.strtoupper(Str::random(12)),
            'package_id' => $plan->code,
            'amount' => $plan->price_tzs,
            'currency' => 'TZS',
            'payment_gateway' => $gateway,
            'phone_number' => $phoneNumber,
            'status' => 'pending',
        ]);

        try {
            $response = $isSelcom
                ? $this->startSelcomCheckout($user, $transaction, $gatewayConfig)
                : Http::withToken((string) $gatewayConfig['token'])
                    ->acceptJson()
                    ->timeout(15)
                    ->post(trim((string) $gatewayConfig['base_url']).'/checkout', [
                    'reference_id' => $transaction->reference_id,
                    'amount' => $transaction->amount,
                    'currency' => $transaction->currency,
                    'phone_number' => $transaction->phone_number,
                    'package_id' => $plan->code,
                    'callback_url' => url('/api/shop/payment-callback'),
                ]);
        } catch (\Throwable $exception) {
            $transaction->update(['status' => 'failed']);
            report($exception);

            throw new RuntimeException('The payment provider could not be reached. No subscription was activated.');
        }

        $selcomResultCode = (string) $response->json('resultcode', '');
        if ($response->failed() || ($isSelcom && ! in_array($selcomResultCode, ['000', '111'], true))) {
            $transaction->update(['status' => 'failed']);

            throw new RuntimeException('The payment provider rejected the request. No subscription was activated.');
        }

        Subscription::query()->create([
            'user_id' => $user->id,
            'subscription_plan_id' => $plan->id,
            'shop_transaction_id' => $transaction->id,
            'status' => 'pending_payment',
        ]);

        return $transaction;
    }

    /** @param array<string, mixed> $config */
    private function startSelcomCheckout(User $user, ShopTransaction $transaction, array $config): \Illuminate\Http\Client\Response
    {
        $orderPayload = [
            'vendor' => (string) $config['vendor'],
            'order_id' => $transaction->reference_id,
            'buyer_email' => $user->email,
            'buyer_name' => $user->name,
            'buyer_phone' => $this->normalizeSelcomPhone($transaction->phone_number),
            'amount' => $transaction->amount,
            'currency' => $transaction->currency,
            'webhook' => base64_encode(url('/api/shop/payment-callback')),
            'merchant_remarks' => $transaction->package_id,
            'no_of_items' => 1,
        ];
        $orderResponse = $this->sendSelcomRequest(
            $transaction,
            $config,
            '/v1/checkout/create-order-minimal',
            $orderPayload,
        );
        if ($orderResponse->failed() || $orderResponse->json('resultcode') !== '000') {
            return $orderResponse;
        }

        return $this->sendSelcomRequest(
            $transaction,
            $config,
            '/v1/checkout/wallet-payment',
            [
                'transid' => $transaction->reference_id,
                'order_id' => $transaction->reference_id,
                'msisdn' => $this->normalizeSelcomPhone($transaction->phone_number),
            ],
        );
    }

    /** @param array<string, mixed> $config
     *  @param array<string, mixed> $payload
     */
    private function sendSelcomRequest(
        ShopTransaction $transaction,
        array $config,
        string $path,
        array $payload,
    ): \Illuminate\Http\Client\Response {
        $timestamp = Carbon::now()->format('Y-m-d\TH:i:sP');
        $signedFields = implode(',', array_keys($payload));
        $signingString = 'timestamp='.$timestamp;
        foreach ($payload as $field => $value) {
            $signingString .= '&'.$field.'='.$value;
        }
        $digest = base64_encode(hash_hmac('sha256', $signingString, (string) $config['api_secret'], true));

        return Http::acceptJson()
            ->withHeaders([
                'Authorization' => 'SELCOM '.base64_encode((string) $config['api_key']),
                'Digest-Method' => 'HS256',
                'Digest' => $digest,
                'Timestamp' => $timestamp,
                'Signed-Fields' => $signedFields,
            ])
            ->timeout(15)
            ->post(trim((string) $config['base_url']).$path, $payload);
    }

    private function normalizeSelcomPhone(string $phoneNumber): string
    {
        $digits = preg_replace('/\D+/', '', $phoneNumber) ?? '';
        if (str_starts_with($digits, '0')) {
            $digits = '255'.substr($digits, 1);
        }

        if (preg_match('/^255\d{9}$/', $digits) !== 1) {
            throw new RuntimeException('Selcom checkout requires a valid Tanzanian mobile number.');
        }

        return $digits;
    }

    public function confirmSelcomCallback(Request $request): Subscription
    {
        $payload = $request->all();
        $referenceId = (string) ($payload['order_id'] ?? '');
        $transaction = ShopTransaction::query()
            ->where('reference_id', $referenceId)
            ->where('payment_gateway', 'selcom')
            ->first();
        if ($transaction === null) {
            throw new RuntimeException('Unknown Selcom payment order.');
        }

        $config = config('services.selcom');
        $timestamp = (string) $request->header('Timestamp');
        $signedFields = array_filter(explode(',', (string) $request->header('Signed-Fields')));
        $digest = (string) $request->header('Digest');
        $authorization = (string) $request->header('Authorization');
        $requiredSignedFields = ['order_id', 'result', 'resultcode', 'payment_status', 'amount'];
        if ($timestamp === '' || $signedFields === [] || $digest === ''
            || array_diff($requiredSignedFields, $signedFields) !== []
            || $authorization !== 'SELCOM '.base64_encode((string) $config['api_key'])
            || $request->header('Digest-Method') !== 'HS256') {
            throw new RuntimeException('Invalid Selcom callback signature.');
        }

        $signingString = 'timestamp='.$timestamp;
        foreach ($signedFields as $field) {
            if (! array_key_exists($field, $payload) || ! is_scalar($payload[$field])) {
                throw new RuntimeException('Invalid Selcom callback fields.');
            }
            $signingString .= '&'.$field.'='.$payload[$field];
        }
        $expectedDigest = base64_encode(hash_hmac(
            'sha256',
            $signingString,
            (string) $config['api_secret'],
            true,
        ));
        if (! hash_equals($expectedDigest, $digest)) {
            throw new RuntimeException('Invalid Selcom callback signature.');
        }

        if (! isset($payload['amount']) || (float) $payload['amount'] !== $transaction->amount) {
            throw new RuntimeException('Selcom callback amount does not match the order.');
        }

        $paymentStatus = match (strtoupper((string) ($payload['payment_status'] ?? ''))) {
            'COMPLETED' => (string) ($payload['result'] ?? '') === 'SUCCESS'
                && (string) ($payload['resultcode'] ?? '') === '000' ? 'paid' : 'failed',
            'CANCELLED', 'USERCANCELLED', 'REJECTED' => 'failed',
            default => throw new RuntimeException('Selcom payment is not complete.'),
        };

        return $this->confirmPayment($referenceId, $paymentStatus);
    }

    public function confirmPayment(string $referenceId, string $paymentStatus): Subscription
    {
        return DB::transaction(function () use ($referenceId, $paymentStatus): Subscription {
            $transaction = ShopTransaction::query()
                ->where('reference_id', $referenceId)
                ->lockForUpdate()
                ->firstOrFail();
            /** @var Subscription|null $subscription */
            $subscription = Subscription::query()
                ->with('plan')
                ->where('shop_transaction_id', $transaction->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($transaction->status !== 'pending') {
                if ($transaction->status === 'paid' && $paymentStatus === 'paid') {
                    return $subscription;
                }

                throw new RuntimeException('This payment has already been processed.');
            }

            if ($paymentStatus === 'failed') {
                $transaction->update(['status' => 'failed']);
                $subscription->update(['status' => 'payment_failed']);

                return $subscription->refresh();
            }

            $currentSubscription = Subscription::query()
                ->where('user_id', $subscription->user_id)
                ->where('status', 'active')
                ->where('activated_at', '<=', now())
                ->where(fn ($query) => $query->whereNull('ends_at')->orWhere('ends_at', '>', now()))
                ->latest('activated_at')
                ->lockForUpdate()
                ->first();

            $activationDate = now();
            if ($currentSubscription !== null) {
                if ($currentSubscription->subscription_plan_id === $subscription->subscription_plan_id
                    && $currentSubscription->ends_at !== null) {
                    $activationDate = $currentSubscription->ends_at->copy();
                } else {
                    $currentSubscription->update(['status' => 'replaced']);
                }
            }

            $subscription->update([
                'status' => 'active',
                'activated_at' => $activationDate,
                'ends_at' => $subscription->plan->duration_days === null
                    ? null
                    : $activationDate->copy()->addDays($subscription->plan->duration_days),
            ]);
            $transaction->update(['status' => 'paid']);

            return $subscription->refresh();
        });
    }
}
