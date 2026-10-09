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

For SMS delivery, configure a Twilio account and an enabled sender in `.env`:

```dotenv
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_FROM_NUMBER=+15005550006
```

The app stores message bodies encrypted with Laravel's `APP_KEY`. Keep that
key stable and backed up; changing it without re-encrypting the messages makes
existing message bodies unreadable.

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
