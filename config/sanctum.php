<?php

use Laravel\Sanctum\Sanctum;

return [
    'stateful' => explode(',', (string) env('SANCTUM_STATEFUL_DOMAINS', sprintf(
        '%s%s',
        'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
        (string) Sanctum::currentApplicationUrlWithPort(),
    ))),
    'guard' => ['web'],
    'expiration' => env('SANCTUM_EXPIRATION', 10080),
    'token_prefix' => env('SANCTUM_TOKEN_PREFIX', ''),
];
