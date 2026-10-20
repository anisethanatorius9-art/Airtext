<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\AirTextLoginCode;
use App\Models\User;
use App\Services\SmsGateway;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function requestCode(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email:rfc', 'max:255'],
        ]);
        $email = Str::lower(trim($validated['email']));
        $code = (string) random_int(100000, 999999);

        Cache::put($this->codeKey($email), Hash::make($code), now()->addMinutes(10));
        Cache::forget($this->attemptKey($email));
        Mail::to($email)->locale(app()->getLocale())->send(new AirTextLoginCode($code));

        return response()->json([
            'message' => __('If this address can receive AirText codes, one has been sent.'),
        ], 202);
    }

    public function verifyCode(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email:rfc', 'max:255'],
            'code' => ['required', 'digits:6'],
            'name' => ['nullable', 'string', 'max:255'],
        ]);
        $email = Str::lower(trim($validated['email']));
        $attemptKey = $this->attemptKey($email);
        $attempts = (int) Cache::get($attemptKey, 0);
        $storedCode = Cache::get($this->codeKey($email));

        if ($attempts >= 5 || ! is_string($storedCode) || ! Hash::check($validated['code'], $storedCode)) {
            Cache::put($attemptKey, $attempts + 1, now()->addMinutes(10));

            throw ValidationException::withMessages([
                'code' => __('The verification code is invalid or expired.'),
            ]);
        }

        Cache::forget($this->codeKey($email));
        Cache::forget($attemptKey);

        $user = User::query()->firstOrCreate(
            ['email' => $email],
            [
                'name' => trim($validated['name'] ?? '') ?: Str::before($email, '@'),
                'password' => Str::random(64),
            ],
        );

        if ($user->email_verified_at === null) {
            $user->forceFill(['email_verified_at' => now()])->save();
        }

        if ($user->phone_verified_at !== null && $user->phone_number !== null) {
            return $this->beginPhoneLogin($user);
        }

        return $this->phoneVerificationResponse($user);
    }

    public function verifyPhoneLoginCode(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'challenge' => ['required', 'string', 'size:64'],
            'code' => ['required', 'digits:6'],
        ]);
        $challengeHash = hash('sha256', $validated['challenge']);
        $challengeKey = 'airtext:login-challenge:'.$challengeHash;
        $attemptKey = 'airtext:login-challenge-attempts:'.$challengeHash;
        $attempts = (int) Cache::get($attemptKey, 0);
        $challenge = Cache::get($challengeKey);

        if ($attempts >= 5 || ! is_array($challenge) || ! Hash::check($validated['code'], $challenge['code_hash'])) {
            Cache::put($attemptKey, $attempts + 1, now()->addMinutes(10));

            throw ValidationException::withMessages([
                'code' => __('The verification code is invalid or expired.'),
            ]);
        }

        Cache::forget($challengeKey);
        Cache::forget($attemptKey);
        $user = User::query()->findOrFail($challenge['user_id']);

        return $this->authenticatedResponse($user);
    }

    private function beginPhoneLogin(User $user): JsonResponse
    {
        $challenge = Str::random(64);
        $code = (string) random_int(100000, 999999);
        $challengeKey = 'airtext:login-challenge:'.hash('sha256', $challenge);

        try {
            $this->sendPhoneVerificationCode(
                app(SmsGateway::class),
                $user->phone_number,
                $code,
                __('Your AirText sign-in verification code is :code. It expires in 10 minutes.', ['code' => $code]),
            );
        } catch (\RuntimeException $exception) {
            report($exception);

            return response()->json(['message' => __('Phone verification is temporarily unavailable.')], 503);
        }

        Cache::put($challengeKey, [
            'user_id' => $user->id,
            'code_hash' => Hash::make($code),
        ], now()->addMinutes(10));

        return response()->json([
            'requires_phone_verification' => true,
            'challenge' => $challenge,
            'phone_hint' => '••••'.substr($user->phone_number, -4),
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    private function authenticatedResponse(User $user): JsonResponse
    {
        return response()->json([
            'token' => $user->createToken(
                'airtext-mobile',
                ['app', 'phone-verification'],
            )->plainTextToken,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    private function phoneVerificationResponse(User $user): JsonResponse
    {
        return response()->json([
            'token' => $user->createToken(
                'airtext-phone-verification',
                ['phone-verification'],
                now()->addMinutes(10),
            )->plainTextToken,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'profile_photo_url' => $user->profile_photo_path
                ? $this->publicStorageUrl($user->profile_photo_path)
                : null,
            'phone_number' => $user->phone_number,
            'phone_verified_at' => $user->phone_verified_at,
            'app_language' => $user->app_language,
            'last_seen_visibility' => $user->last_seen_visibility,
            'profile_picture_visibility' => $user->profile_picture_visibility,
            'about_visibility' => $user->about_visibility,
            'links_visibility' => $user->links_visibility,
            'status_visibility' => $user->status_visibility,
            'disappearing_messages' => (bool) $user->disappearing_messages,
        ]);
    }

    public function preferences(Request $request): JsonResponse
    {
        return response()->json([
            'preferences' => $this->userPreferences($request->user()),
        ]);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'app_language' => ['sometimes', 'nullable', 'string', 'max:80'],
            'last_seen_visibility' => ['sometimes', 'nullable', 'in:Everyone,My contacts,My contacts except...,Nobody'],
            'profile_picture_visibility' => ['sometimes', 'nullable', 'in:Everyone,My contacts,Nobody'],
            'about_visibility' => ['sometimes', 'nullable', 'in:Everyone,My contacts,Nobody'],
            'links_visibility' => ['sometimes', 'nullable', 'in:Everyone,My contacts,Nobody'],
            'status_visibility' => ['sometimes', 'nullable', 'in:Everyone,My contacts,Nobody'],
            'disappearing_messages' => ['sometimes', 'boolean'],
            'storage_settings' => ['sometimes', 'array'],
            'storage_settings.use_less_data_for_calls' => ['sometimes', 'boolean'],
            'storage_settings.upload_quality' => ['sometimes', 'in:standard,hd'],
            'storage_settings.auto_download_quality' => ['sometimes', 'in:auto,high'],
            'storage_settings.mobile_data_downloads' => ['sometimes', 'in:none,photos,all'],
            'storage_settings.wifi_downloads' => ['sometimes', 'in:none,photos,all'],
            'storage_settings.roaming_downloads' => ['sometimes', 'in:none,photos,all'],
            'storage_settings.auto_download_photos' => ['sometimes', 'boolean'],
            'storage_settings.auto_download_videos' => ['sometimes', 'boolean'],
            'storage_settings.auto_download_stickers' => ['sometimes', 'boolean'],
            'storage_settings.auto_download_voice' => ['sometimes', 'boolean'],
            'messaging_settings' => ['sometimes', 'array'],
            'messaging_settings.default_payload_prefix' => ['sometimes', 'in:MSG:,STAT:,ACK:'],
            'messaging_settings.delivery_receipts' => ['sometimes', 'boolean'],
            'messaging_settings.sms_fallback_enabled' => ['sometimes', 'boolean'],
        ]);

        $user = $request->user();
        foreach ($validated as $key => $value) {
            if ($value === null) {
                continue;
            }
            if (in_array($key, ['storage_settings', 'messaging_settings'], true)) {
                $user->{$key} = array_merge($user->{$key} ?? [], $value);

                continue;
            }
            $user->{$key} = $value;
        }
        $user->save();

        return response()->json([
            'preferences' => $this->userPreferences($user),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
        ]);
        $user = $request->user();
        $user->name = trim($validated['name']);
        $user->save();

        return response()->json(['user' => [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone_number' => $user->phone_number,
            'phone_verified_at' => $user->phone_verified_at,
            'profile_photo_url' => $user->profile_photo_path
                ? $this->publicStorageUrl($user->profile_photo_path)
                : null,
        ]]);
    }

    public function updateProfilePhoto(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'photo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        $user = $request->user();
        $oldPath = $user->profile_photo_path;
        $newPath = $validated['photo']->store('profile-photos/'.$user->id, 'public');

        $user->forceFill(['profile_photo_path' => $newPath])->save();
        if ($oldPath !== null) {
            Storage::disk('public')->delete($oldPath);
        }

        return response()->json([
            'profile_photo_url' => $this->publicStorageUrl($newPath),
        ]);
    }

    public function deleteProfilePhoto(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user->profile_photo_path !== null) {
            Storage::disk('public')->delete($user->profile_photo_path);
            $user->forceFill(['profile_photo_path' => null])->save();
        }

        return response()->json(['profile_photo_url' => null]);
    }

    public function requestPhoneCode(Request $request, SmsGateway $smsGateway): JsonResponse
    {
        $validated = $request->validate([
            'phone_number' => ['required', 'string', 'regex:/^\\+[1-9][0-9]{7,14}$/', 'unique:users,phone_number,'.$request->user()->id],
        ]);
        $phoneNumber = $validated['phone_number'];
        $code = (string) random_int(100000, 999999);
        $userId = $request->user()->id;

        try {
            $this->sendPhoneVerificationCode(
                $smsGateway,
                $phoneNumber,
                $code,
                __('Your AirText verification code is :code. It expires in 10 minutes.', ['code' => $code]),
            );
        } catch (\RuntimeException $exception) {
            report($exception);

            return response()->json(['message' => 'Phone verification is temporarily unavailable.'], 503);
        }

        Cache::put($this->phoneCodeKey($userId, $phoneNumber), Hash::make($code), now()->addMinutes(10));
        Cache::forget($this->phoneAttemptKey($userId, $phoneNumber));

        return response()->json(['message' => __('A verification code has been sent.')], 202);
    }

    private function sendPhoneVerificationCode(
        SmsGateway $smsGateway,
        string $phoneNumber,
        string $code,
        string $message,
    ): void {
        $twilioConfigured = config('services.twilio.sid')
            && config('services.twilio.token')
            && config('services.twilio.from');

        if (app()->isLocal() && ! $twilioConfigured) {
            Log::info('AirText local phone verification code.', [
                'phone_number' => $phoneNumber,
                'code' => $code,
            ]);

            return;
        }

        $smsGateway->send($phoneNumber, $message);
    }

    public function verifyPhoneCode(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone_number' => ['required', 'string', 'regex:/^\\+[1-9][0-9]{7,14}$/', 'unique:users,phone_number,'.$request->user()->id],
            'code' => ['required', 'digits:6'],
        ]);
        $userId = $request->user()->id;
        $phoneNumber = $validated['phone_number'];
        $attemptKey = $this->phoneAttemptKey($userId, $phoneNumber);
        $attempts = (int) Cache::get($attemptKey, 0);
        $storedCode = Cache::get($this->phoneCodeKey($userId, $phoneNumber));

        if ($attempts >= 5 || ! is_string($storedCode) || ! Hash::check($validated['code'], $storedCode)) {
            Cache::put($attemptKey, $attempts + 1, now()->addMinutes(10));

            throw ValidationException::withMessages([
                'code' => __('The verification code is invalid or expired.'),
            ]);
        }

        Cache::forget($this->phoneCodeKey($userId, $phoneNumber));
        Cache::forget($attemptKey);
        $user = $request->user();
        $user->phone_number = $phoneNumber;
        $user->phone_verified_at = now();
        $user->save();

        $token = $request->user()->currentAccessToken();
        $response = [
            'phone_number' => $user->phone_number,
            'phone_verified_at' => $user->phone_verified_at,
        ];

        if ($token->can('phone-verification') && ! $token->can('*')) {
            $token->delete();
            $response['token'] = $user->createToken(
                'airtext-mobile',
                ['app', 'phone-verification'],
            )->plainTextToken;
        }

        return response()->json($response);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => __('Signed out.')]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();
        $userId = $user->id;
        $ownedChannelIds = DB::table('channels')
            ->where('owner_id', $userId)
            ->pluck('id');
        $conversationIds = DB::table('conversations')
            ->where(fn ($query) => $query
                ->where('owner_id', $userId)
                ->orWhere('recipient_id', $userId))
            ->pluck('id');
        $localMediaPaths = DB::table('messages')
            ->whereIn('conversation_id', $conversationIds)
            ->where('message_type', 'voice')
            ->whereNotNull('media_path')
            ->pluck('media_path')
            ->unique()
            ->values()
            ->all();
        $mediaPaths = DB::table('statuses')
            ->where('user_id', $userId)
            ->pluck('media_path')
            ->merge([$user->profile_photo_path])
            ->merge(DB::table('messages')
                ->where('sender_id', $userId)
                ->pluck('media_path'))
            ->merge(DB::table('messages')
                ->whereIn('conversation_id', $conversationIds)
                ->pluck('media_path'))
            ->merge(DB::table('channels')
                ->where('owner_id', $userId)
                ->pluck('avatar_path'))
            ->merge(DB::table('channel_posts')
                ->where('author_id', $userId)
                ->orWhereIn('channel_id', $ownedChannelIds)
                ->pluck('media_path'))
            ->filter(fn (?string $path): bool => $path !== null)
            ->unique()
            ->values()
            ->all();

        DB::transaction(function () use ($user, $userId): void {
            DB::table('personal_access_tokens')
                ->where('tokenable_type', $user::class)
                ->where('tokenable_id', $userId)
                ->delete();
            DB::table('sessions')->where('user_id', $userId)->delete();
            DB::table('password_reset_tokens')->where('email', $user->email)->delete();
            DB::table('messages')->where('sender_id', $userId)->delete();
            DB::table('conversations')
                ->where(fn ($query) => $query
                    ->where('owner_id', $userId)
                    ->orWhere('recipient_id', $userId))
                ->delete();
            DB::table('statuses')->where('user_id', $userId)->delete();
            DB::table('channel_posts')->where('author_id', $userId)->delete();
            DB::table('channels')->where('owner_id', $userId)->delete();
            DB::table('shop_transactions')->where('user_id', $userId)->delete();
            $user->delete();
        });

        Cache::forget($this->codeKey($user->email));
        Cache::forget($this->attemptKey($user->email));
        if ($user->phone_number !== null) {
            Cache::forget($this->phoneCodeKey($userId, $user->phone_number));
            Cache::forget($this->phoneAttemptKey($userId, $user->phone_number));
        }
        Storage::disk('public')->delete($mediaPaths);
        Storage::disk('local')->delete($localMediaPaths);

        return response()->json(['message' => __('Your account and associated data have been deleted.')]);
    }

    private function userPreferences(User $user): array
    {
        return [
            'app_language' => $user->app_language ?? 'English',
            'last_seen_visibility' => $user->last_seen_visibility ?? 'Everyone',
            'profile_picture_visibility' => $user->profile_picture_visibility ?? 'My contacts',
            'about_visibility' => $user->about_visibility ?? 'My contacts',
            'links_visibility' => $user->links_visibility ?? 'My contacts',
            'status_visibility' => $user->status_visibility ?? 'Everyone',
            'disappearing_messages' => (bool) $user->disappearing_messages,
            'storage_settings' => empty($user->storage_settings) ? (object) [] : $user->storage_settings,
            'messaging_settings' => empty($user->messaging_settings) ? (object) [] : $user->messaging_settings,
        ];
    }

    private function codeKey(string $email): string
    {
        return 'airtext:otp:'.hash('sha256', $email);
    }

    private function attemptKey(string $email): string
    {
        return 'airtext:otp-attempts:'.hash('sha256', $email);
    }

    private function phoneCodeKey(int $userId, string $phoneNumber): string
    {
        return 'airtext:phone-otp:'.$userId.':'.hash('sha256', $phoneNumber);
    }

    private function phoneAttemptKey(int $userId, string $phoneNumber): string
    {
        return 'airtext:phone-otp-attempts:'.$userId.':'.hash('sha256', $phoneNumber);
    }

    private function publicStorageUrl(string $path): string
    {
        /** @var \Illuminate\Filesystem\FilesystemAdapter $disk */
        $disk = Storage::disk('public');

        return $disk->url($path);
    }
}
