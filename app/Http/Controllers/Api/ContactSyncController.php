<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ContactSyncController extends Controller
{
    public function sync(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone_numbers' => ['present', 'array', 'max:5000'],
            'phone_numbers.*' => ['required', 'string', 'regex:/^\\+[1-9]\\d{7,14}$/', 'distinct'],
        ]);
        $user = $request->user();

        $contactIds = User::query()
            ->whereNotNull('phone_verified_at')
            ->whereIn('phone_number', $validated['phone_numbers'])
            ->whereKeyNot($user->id)
            ->pluck('id');

        DB::transaction(function () use ($user, $contactIds): void {
            DB::table('user_contacts')->where('user_id', $user->id)->delete();

            if ($contactIds->isNotEmpty()) {
                $now = now();
                DB::table('user_contacts')->insert($contactIds->map(fn (int $contactId): array => [
                    'user_id' => $user->id,
                    'contact_user_id' => $contactId,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])->all());
            }
        });

        return response()->json([
            'message' => 'Contacts synced.',
            'matched_contacts' => $contactIds->count(),
        ]);
    }
}
