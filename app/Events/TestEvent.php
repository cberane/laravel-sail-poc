<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

class TestEvent implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(
        private string $message = 'Hello World'
    ) {}

    public function broadcastOn(): array
    {
        return [
            new Channel(
                'test-channel'
            ),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'message' => $this->message,
        ];
    }
}
