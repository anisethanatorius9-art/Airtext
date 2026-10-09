<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class SmsGateway
{
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
