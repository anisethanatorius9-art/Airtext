<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\SmsGateway;
use Illuminate\Http\JsonResponse;
use RuntimeException;

class SmsGatewayController extends Controller
{
    public function show(SmsGateway $gateway): JsonResponse
    {
        return response()->json([
            'provider' => 'Twilio',
            'configured' => $gateway->isConfigured(),
            'sender_number' => $gateway->maskedSenderNumber(),
        ]);
    }

    public function test(SmsGateway $gateway): JsonResponse
    {
        try {
            $gateway->testConnection();
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 503);
        }

        return response()->json(['message' => 'Twilio connection verified.']);
    }
}
