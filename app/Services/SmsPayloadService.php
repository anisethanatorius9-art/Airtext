<?php

namespace App\Services;

class SmsPayloadService
{
    public function encode(string $type, string $content): string
    {
        return match (strtoupper($type)) {
            'STATUS' => "STAT:{$content}",
            'ACK' => "ACK:{$content}",
            default => "MSG:{$content}",
        };
    }

    public function decode(string $rawPayload): array
    {
        return match (true) {
            str_starts_with($rawPayload, 'STAT:') => ['type' => 'status', 'content' => substr($rawPayload, 5)],
            str_starts_with($rawPayload, 'ACK:') => ['type' => 'receipt', 'content' => substr($rawPayload, 4)],
            str_starts_with($rawPayload, 'MSG:') => ['type' => 'message', 'content' => substr($rawPayload, 4)],
            default => ['type' => 'message', 'content' => $rawPayload],
        };
    }
}
