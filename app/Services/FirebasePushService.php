<?php

namespace App\Services;

use App\Models\DevicePushToken;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class FirebasePushService
{
    public function sendMessageAlert(int $userId, int $conversationId, bool $priority = false): void
    {
        $projectId = (string) config('services.firebase.project_id');
        $clientEmail = (string) config('services.firebase.client_email');
        $privateKey = str_replace('\\n', "\n", (string) config('services.firebase.private_key'));

        if ($projectId === '' || $clientEmail === '' || $privateKey === '') {
            return;
        }

        $tokens = DevicePushToken::query()->where('user_id', $userId)->get();
        if ($tokens->isEmpty()) return;

        try {
            $accessToken = $this->accessToken($clientEmail, $privateKey);
            foreach ($tokens as $deviceToken) {
                $tone = match ($deviceToken->message_tone) {
                    'Modern ping' => 'modern_ping',
                    'Soft echo' => 'soft_echo',
                    default => 'chime',
                };
                $sound = "airtext_{$tone}";
                $payload = [
                    'message' => [
                        'token' => $deviceToken->token,
                        'notification' => [
                            'title' => 'New AirText message',
                            'body' => 'You received a new message.',
                        ],
                        'data' => [
                            'type' => 'message',
                            'conversation_id' => (string) $conversationId,
                        ],
                        'android' => [
                            'priority' => $priority ? 'high' : 'normal',
                            'notification' => [
                                'channel_id' => "airtext_messages_{$tone}",
                                'sound' => $sound,
                            ],
                        ],
                        'apns' => [
                            'headers' => ['apns-priority' => $priority ? '10' : '5'],
                            'payload' => ['aps' => ['sound' => "{$sound}.wav"]],
                        ],
                    ],
                ];
                $response = Http::withToken($accessToken)
                    ->acceptJson()
                    ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", $payload);

                if ($response->status() === 404 ||
                    $response->json('error.details.0.errorCode') === 'UNREGISTERED') {
                    $deviceToken->delete();
                } elseif (! $response->successful()) {
                    Log::warning('AirText message push delivery failed.', [
                        'user_id' => $userId,
                        'status' => $response->status(),
                    ]);
                }
            }
        } catch (Throwable $exception) {
            Log::warning('AirText message push service is unavailable.', [
                'user_id' => $userId,
                'exception' => $exception::class,
            ]);
        }
    }

    public function sendCallInvite(int $userId, string $callId, string $callerName, bool $group = false): void
    {
        $projectId = (string) config('services.firebase.project_id');
        $clientEmail = (string) config('services.firebase.client_email');
        $privateKey = str_replace('\\n', "\n", (string) config('services.firebase.private_key'));

        if ($projectId === '' || $clientEmail === '' || $privateKey === '') {
            return;
        }

        $tokens = DevicePushToken::query()->where('user_id', $userId)->get();
        if ($tokens->isEmpty()) {
            return;
        }

        try {
            $accessToken = $this->accessToken($clientEmail, $privateKey);
            foreach ($tokens as $deviceToken) {
                $response = Http::withToken($accessToken)
                    ->acceptJson()
                    ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                        'message' => [
                            'token' => $deviceToken->token,
                            'notification' => [
                                'title' => $group ? 'Incoming AirText group call' : 'Incoming AirText video call',
                                'body' => $group
                                    ? "{$callerName} started a group call."
                                    : "{$callerName} is calling.",
                            ],
                            'data' => [
                                'type' => $group ? 'group_call' : 'direct_call',
                                'call_id' => $callId,
                            ],
                            'android' => [
                                'priority' => 'high',
                                'notification' => ['sound' => 'default'],
                            ],
                            'apns' => [
                                'headers' => ['apns-priority' => '10'],
                                'payload' => ['aps' => ['sound' => 'default']],
                            ],
                        ],
                    ]);

                if ($response->status() === 404 ||
                    $response->json('error.details.0.errorCode') === 'UNREGISTERED') {
                    $deviceToken->delete();
                } elseif (! $response->successful()) {
                    Log::warning('AirText call push delivery failed.', [
                        'user_id' => $userId,
                        'status' => $response->status(),
                    ]);
                }
            }
        } catch (Throwable $exception) {
            Log::warning('AirText call push service is unavailable.', [
                'user_id' => $userId,
                'exception' => $exception::class,
            ]);
        }
    }

    private function accessToken(string $clientEmail, string $privateKey): string
    {
        return Cache::remember('firebase-fcm-access-token', now()->addMinutes(50), function () use ($clientEmail, $privateKey): string {
            $issuedAt = now()->timestamp;
            $assertion = JWT::encode([
                'iss' => $clientEmail,
                'sub' => $clientEmail,
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $issuedAt,
                'exp' => $issuedAt + 3600,
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            ], $privateKey, 'RS256');

            $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $assertion,
            ]);
            $response->throw();

            return (string) $response->json('access_token');
        });
    }
}
