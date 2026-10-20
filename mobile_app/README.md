# AirText Mobile

## Backend setup

From the Laravel project root, install dependencies and run migrations:

```powershell
composer install
php artisan migrate
```

Configure a real mail transport in `.env` for email sign-in codes. For SMTP,
set `MAIL_MAILER=smtp`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`,
`MAIL_PASSWORD`, `MAIL_SCHEME`, and `MAIL_FROM_ADDRESS`. The default local
mailer writes messages to the Laravel log and does not deliver email.

For local app review without SMTP or Twilio, keep `APP_ENV=local` and
`MAIL_MAILER=log`. Request sign-in codes in the app, then read the recent OTPs
from the Laravel log at `storage/logs/laravel.log`:

```powershell
Select-String -Path storage\logs\laravel.log -Pattern 'verification code|AirText local phone verification code' | Select-Object -Last 8
```

Email and phone codes remain random, expire after 10 minutes, and are limited
to five attempts. When Twilio is not configured, phone verification codes are
written to the log only in the local environment; production still requires a
real SMS provider. No fixed development OTP or authentication bypass is used.

For SMS delivery, configure a Twilio account and an enabled sender in `.env`:

```dotenv
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_FROM_NUMBER=+15005550006
```

The app stores message bodies encrypted with Laravel's `APP_KEY`. Keep that
key stable and backed up; changing it without re-encrypting the messages makes
existing message bodies unreadable.

## AirText video calls

Video calls use WebRTC media in the AirText app and Laravel Reverb for private
call signaling and real-time AirText message notifications. New-message
broadcasts contain only conversation and message IDs; Flutter then reloads the
authorized conversation data from the API. A 15-second API sync remains as a
fallback when a WebSocket connection is unavailable. No hosted meeting service
is used. Calls currently support one-to-one AirText conversations; group video
calling is not implemented.

Set `BROADCAST_CONNECTION=reverb` and the `REVERB_APP_ID`, `REVERB_APP_KEY`,
`REVERB_APP_SECRET`, `REVERB_HOST`, `REVERB_PORT`, and `REVERB_SCHEME` values
in the Laravel `.env`. Keep the app secret server-side. Run Reverb alongside
Laravel in development:

```powershell
php artisan reverb:start --host=0.0.0.0 --port=8080
```

For calls across mobile networks, configure a Coturn server with the REST API
shared secret in Laravel only:

```dotenv
TURN_STUN_URLS=stun:turn.example.com:3478
TURN_URLS=turn:turn.example.com:3478,turns:turn.example.com:5349
TURN_SHARED_SECRET=your-coturn-rest-secret
TURN_CREDENTIAL_TTL=3600
```

Laravel issues temporary TURN credentials to authenticated users. Never pass
`TURN_SHARED_SECRET` to Flutter. Configure Coturn DNS, TLS certificates, and
firewall/relay port ranges before expecting calls to connect across NAT.

For an Android emulator, point the mobile build to the host machine's local
services. Replace the Reverb key with the public `REVERB_APP_KEY` value from
the Laravel environment:

```powershell
cd mobile_app
flutter run --dart-define=AIRTEXT_API_URL=http://10.0.2.2:8000/api --dart-define=AIRTEXT_REVERB_HOST=10.0.2.2 --dart-define=AIRTEXT_REVERB_PORT=8080 --dart-define=AIRTEXT_REVERB_KEY=your-reverb-app-key
```

For production, use HTTPS/WSS hostnames and port 443, and add
`--dart-define=AIRTEXT_REVERB_TLS=true`. A physical phone must use reachable
server hostnames rather than the Android emulator address.

## Run the app

For an Android emulator using the local Laravel server:

```powershell
php artisan serve --host=0.0.0.0
cd mobile_app
flutter run --dart-define=AIRTEXT_API_URL=http://10.0.2.2:8000/api
```

Set `AIRTEXT_API_URL` to the HTTPS API URL when building for a device or
production. The mobile app authenticates by email OTP, stores a Sanctum bearer
token in Keychain/Android Keystore, and syncs AirText conversations through the API. SMS messages
are sent by Twilio when configured; this implementation does not provide
Bluetooth mesh or inbound SMS routing.

Sanctum bearer tokens expire after seven days by default. Set
`SANCTUM_EXPIRATION` to change the lifetime in minutes.
