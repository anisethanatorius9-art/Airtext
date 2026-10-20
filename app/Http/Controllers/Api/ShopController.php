<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use App\Services\ShopSubscriptionCheckout;
use Illuminate\Http\Request;
use RuntimeException;

class ShopController extends Controller
{
    /**
     * Initiate a real mobile-money checkout request.
     */
    public function checkout(Request $request, ShopSubscriptionCheckout $checkout)
    {
        $validated = $request->validate([
            'package_id' => ['required', 'string', 'exists:subscription_plans,code'],
            'phone_number' => ['required', 'string', 'min:10'],
            'gateway' => ['required', 'in:azampay,selcom'],
        ]);

        $plan = SubscriptionPlan::query()
            ->where('code', $validated['package_id'])
            ->where('is_active', true)
            ->firstOrFail();

        if ($plan->price_tzs === 0) {
            return response()->json([
                'status' => 'invalid_plan',
                'message' => 'Free plans must be activated without a payment checkout.',
            ], 422);
        }

        try {
            $transaction = $checkout->start(
                $request->user(),
                $plan,
                $validated['phone_number'],
                $validated['gateway'],
            );
        } catch (RuntimeException $exception) {
            $status = str_contains($exception->getMessage(), 'not configured') ? 503 : 400;

            return response()->json([
                'status' => $status === 503 ? 'unavailable' : 'error',
                'message' => $exception->getMessage(),
            ], $status);
        }

        return response()->json([
            'status' => 'pending_payment',
            'message' => 'Payment request sent. The subscription will activate after payment confirmation.',
            'reference_id' => $transaction->reference_id,
        ], 202);
    }

    public function paymentCallback(Request $request, ShopSubscriptionCheckout $checkout)
    {
        if ($request->has('order_id')) {
            try {
                $subscription = $checkout->confirmSelcomCallback($request);
            } catch (RuntimeException $exception) {
                return response()->json(['message' => $exception->getMessage()], 409);
            }

            return response()->json([
                'status' => $subscription->status,
                'ends_at' => $subscription->ends_at,
            ]);
        }

        $secret = (string) config('services.shop_webhook_secret');
        $signature = (string) $request->header('X-AirText-Payment-Signature');
        if ($secret === '' || $signature === '' || ! hash_equals(
            hash_hmac('sha256', $request->getContent(), $secret),
            $signature,
        )) {
            return response()->json(['message' => 'Invalid payment callback signature.'], 401);
        }

        $validated = $request->validate([
            'reference_id' => ['required', 'string', 'max:64'],
            'status' => ['required', 'in:paid,failed'],
        ]);

        try {
            $subscription = $checkout->confirmPayment(
                $validated['reference_id'],
                $validated['status'],
            );
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 409);
        }

        return response()->json([
            'status' => $subscription->status,
            'ends_at' => $subscription->ends_at,
        ]);
    }
}
