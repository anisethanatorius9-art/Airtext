<?php

namespace App\Services;

use App\Models\GroupCallSession;
use App\Models\User;
use Firebase\JWT\JWT;
use LogicException;

class LiveKitTokenService
{
    public function issue(GroupCallSession $session, User $user): string
    {
        $apiKey = (string) config('services.livekit.api_key');
        $apiSecret = (string) config('services.livekit.api_secret');

        if ($apiKey === '' || strlen($apiSecret) < 32) {
            throw new LogicException('LiveKit server credentials are not configured.');
        }

        $issuedAt = now()->timestamp;

        return JWT::encode([
            'iss' => $apiKey,
            'sub' => (string) $user->id,
            'nbf' => $issuedAt,
            'iat' => $issuedAt,
            'exp' => now()->addMinutes(30)->timestamp,
            'name' => $user->name,
            'video' => [
                'roomJoin' => true,
                'room' => $session->room_name,
                'canPublish' => true,
                'canSubscribe' => true,
                'canPublishData' => true,
            ],
        ], $apiSecret, 'HS256');
    }
}