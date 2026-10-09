<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\AirTextLoginCode;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
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
        Mail::to($email)->send(new AirTextLoginCode($code));

        return response()->json([
            'message' => 'If this address can receive AirText codes, one has been sent.',
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
                'code' => 'The verification code is invalid or expired.',
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

        return response()->json([
            'token' => $user->createToken('airtext-mobile')->plainTextToken,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'id' => $request->user()->id,
            'name' => $request->user()->name,
            'email' => $request->user()->email,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Signed out.']);
    }

    private function codeKey(string $email): string
    {
        return 'airtext:otp:'.hash('sha256', $email);
    }

    private function attemptKey(string $email): string
    {
        return 'airtext:otp-attempts:'.hash('sha256', $email);
    }
}
