<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

class SetAppLocale
{
    private const SUPPORTED_LOCALES = [
        'en', 'sw', 'fr', 'es', 'ar', 'zh', 'pt', 'hi', 'ru', 'de',
        'ja', 'ko', 'it', 'tr', 'vi', 'ur', 'fa', 'pl', 'uk', 'nl',
        'el', 'bn', 'pa', 'jv', 'te', 'mr', 'ta', 'gu', 'ha', 'yo',
        'ig', 'am', 'zu', 'xh', 'so', 'id', 'tl', 'th', 'hu', 'cs',
        'sv', 'da', 'fi', 'no', 'ro', 'he', 'bg', 'sr', 'hr', 'sk',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        $locale = $request->getPreferredLanguage(self::SUPPORTED_LOCALES)
            ?? config('app.fallback_locale', 'en');

        App::setLocale($locale);

        return $next($request);
    }
}
