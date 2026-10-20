<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /** @param array<int, int> $userIds */
    public function __construct(
        public readonly int $conversationId,
        public readonly int $messageId,
        public readonly array $userIds,
    ) {}

    /** @return array<int, PrivateChannel> */
    public function broadcastOn(): array
    {
        return array_map(
            fn (int $userId): PrivateChannel => new PrivateChannel('users.'.$userId),
            $this->userIds,
        );
    }

    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    /** @return array<string, int> */
    public function broadcastWith(): array
    {
        return [
            'conversation_id' => $this->conversationId,
            'message_id' => $this->messageId,
        ];
    }
}
