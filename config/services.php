<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'twilio' => [
        'sid' => env('TWILIO_ACCOUNT_SID'),
        'token' => env('TWILIO_AUTH_TOKEN'),
        'from' => env('TWILIO_FROM_NUMBER'),
    ],

    'turn' => [
        'stun_urls' => env('TURN_STUN_URLS', ''),
        'urls' => env('TURN_URLS', ''),
        'shared_secret' => env('TURN_SHARED_SECRET', ''),
        'credential_ttl' => env('TURN_CREDENTIAL_TTL', 3600),
    ],

    'livekit' => [
        'url' => env('LIVEKIT_URL', ''),
        'api_key' => env('LIVEKIT_API_KEY', ''),
        'api_secret' => env('LIVEKIT_API_SECRET', ''),
    ],

    'translation' => [
        'provider' => env('AIRTEXT_TRANSLATION_PROVIDER', 'libre'),
        'url' => env(
            'AIRTEXT_TRANSLATION_URL',
            'http://127.0.0.1:5000/translate',
        ),
        'key' => env('AIRTEXT_TRANSLATION_KEY', env('AIRTEXT_TRANSLATION_API_KEY', '')),
    ],

    'firebase' => [
        'project_id' => env('FIREBASE_PROJECT_ID', ''),
        'client_email' => env('FIREBASE_CLIENT_EMAIL', ''),
        'private_key' => env('FIREBASE_PRIVATE_KEY', ''),
    ],

    'azampay' => [
        'base_url' => env('AZAMPAY_BASE_URL', ''),
        'token' => env('AZAMPAY_TOKEN', ''),
    ],

    'selcom' => [
        'base_url' => env('SELCOM_BASE_URL', ''),
        'api_key' => env('SELCOM_API_KEY', ''),
        'api_secret' => env('SELCOM_API_SECRET', ''),
        'vendor' => env('SELCOM_VENDOR', ''),
    ],

    'shop_webhook_secret' => env('SHOP_WEBHOOK_SECRET', ''),

];
