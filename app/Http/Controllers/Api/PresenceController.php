<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PresenceController extends Controller
{
    public function heartbeat(Request $request): JsonResponse
    {
        $request->user()->forceFill(['last_seen_at' => now()])->save();

        return response()->json(['last_seen_at' => $request->user()->last_seen_at]);
    }
}