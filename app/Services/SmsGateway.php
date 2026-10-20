<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class SmsGateway
{
    public function isConfigured(): bool
    {
        return (bool) (config('services.twilio.sid') && config('services.twilio.token') && config('services.twilio.from'));
    }

    public function maskedSenderNumber(): ?string
    {
        $sender = config('services.twilio.from');
        if (! is_string($sender) || $sender === '') {
            return null;
        }

        return substr($sender, 0, 4).'****'.substr($sender, -2);
    }

    public function testConnection(): void
    {
        $sid = config('services.twilio.sid');
        $token = config('services.twilio.token');
        $from = config('services.twilio.from');
        if (! $sid || ! $token || ! $from) {
            throw new RuntimeException('SMS delivery is not configured.');
        }

        try {
            $response = Http::withBasicAuth($sid, $token)
                ->timeout(15)
                ->get("https://api.twilio.com/2010-04-01/Accounts/{$sid}.json");
        } catch (ConnectionException $exception) {
            throw new RuntimeException('The SMS provider could not be reached.', previous: $exception);
        }

        if ($response->failed()) {
            throw new RuntimeException('The SMS provider rejected the configured credentials.');
        }
    }

    public function send(string $to, string $body): void
    {
        $sid = config('services.twilio.sid');
        $token = config('services.twilio.token');
        $from = config('services.twilio.from');

        if (! $sid || ! $token || ! $from) {
            throw new RuntimeException('SMS delivery is not configured.');
        }

        try {
            $response = Http::asForm()
                ->withBasicAuth($sid, $token)
                ->timeout(15)
                ->post("https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json", [
                    'From' => $from,
                    'To' => $to,
                    'Body' => $body,
                ]);
        } catch (ConnectionException $exception) {
            throw new RuntimeException('The SMS provider could not be reached.', previous: $exception);
        }

        if ($response->failed()) {
            throw new RuntimeException('The SMS provider rejected the message.');
        }
    }
}
