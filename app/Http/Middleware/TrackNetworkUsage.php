<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class TrackNetworkUsage
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        $user = $request->user();

        if ($user === null || ! $user->exists) {
            return $response;
        }

        $uploadedBytes = max(0, (int) $request->header('Content-Length', 0));
        $responseLength = (int) $response->headers->get('Content-Length', 0);
        $responseContent = $response->getContent();
        $downloadedBytes = max(0, $responseLength > 0
            ? $responseLength
            : (is_string($responseContent) ? strlen($responseContent) : 0));
        $periodStart = now()->startOfMonth()->toDateString();
        $now = now();

        DB::table('user_network_usage')->insertOrIgnore([
            'user_id' => $user->id,
            'period_start' => $periodStart,
            'uploaded_bytes' => 0,
            'downloaded_bytes' => 0,
            'request_count' => 0,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('user_network_usage')
            ->where('user_id', $user->id)
            ->where('period_start', $periodStart)
            ->increment('uploaded_bytes', $uploadedBytes, [
                'downloaded_bytes' => DB::raw('downloaded_bytes + '.$downloadedBytes),
                'request_count' => DB::raw('request_count + 1'),
                'updated_at' => $now,
            ]);

        return $response;
    }
}
