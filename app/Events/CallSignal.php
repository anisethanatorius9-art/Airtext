<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CallSignal implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /** @param array<string, mixed> $payload */
    public function __construct(
        public readonly int $recipientId,
        public readonly string $callId,
        public readonly string $kind,
        public readonly int $senderId,
        public readonly array $payload = [],
    ) {}

    /** @return array<int, PrivateChannel> */
    public function broadcastOn(): array
    {
        return [new PrivateChannel('users.'.$this->recipientId)];
    }

    public function broadcastAs(): string
    {
        return 'call.signal';
    }

    /** @return array<string, mixed> */
    public function broadcastWith(): array
    {
        return [
            'call_id' => $this->callId,
            'kind' => $this->kind,
            'sender_id' => $this->senderId,
            'payload' => $this->payload,
        ];
    }
}
