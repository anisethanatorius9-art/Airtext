<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Throwable;

class MessageTranslationService
{
    public function translate(
        string $text,
        string $targetLanguage,
        string $cacheScope,
        string $sourceLanguage = 'auto',
    ): string {
        $provider = (string) config('services.translation.provider', 'libre');
        $url = rtrim((string) config('services.translation.url'), '/');

        if ($url === '') {
            return $text;
        }

        $cacheKey = 'airtext:translation:'.hash('sha256', implode('|', [
            $provider,
            $url,
            $cacheScope,
            $sourceLanguage,
            $targetLanguage,
            hash('sha256', $text),
        ]));

        try {
            $encryptedTranslation = Cache::remember(
                $cacheKey,
                now()->addDays(30),
                fn (): string => Crypt::encryptString(
                    $this->requestTranslation(
                        $provider,
                        $url,
                        $text,
                        $targetLanguage,
                        $sourceLanguage,
                    ),
                ),
            );

            return Crypt::decryptString($encryptedTranslation);
        } catch (Throwable $exception) {
            report($exception);

            return $text;
        }
    }

    private function requestTranslation(
        string $provider,
        string $url,
        string $text,
        string $targetLanguage,
        string $sourceLanguage,
    ): string {
        try {
            $translation = match ($provider) {
                'google_free' => $this->translateWithGoogle($url, $text, $targetLanguage, $sourceLanguage),
                'libre', 'libretranslate' => $this->translateWithLibreTranslate($url, $text, $targetLanguage, $sourceLanguage),
                default => throw new RuntimeException('Unsupported translation provider.'),
            };
        } catch (Throwable $exception) {
            throw new RuntimeException('The translation provider request failed.', previous: $exception);
        }

        if (! is_string($translation) || trim($translation) === '') {
            throw new RuntimeException('The translation provider returned no translation.');
        }

        return $translation;
    }

    private function translateWithGoogle(
        string $url,
        string $text,
        string $targetLanguage,
        string $sourceLanguage,
    ): string {
        $response = Http::withUserAgent('Mozilla/5.0 (compatible; AirText/1.0)')
            ->acceptJson()
            ->timeout(15)
            ->get($url, [
                'client' => 'gtx',
                'sl' => $sourceLanguage,
                'tl' => $targetLanguage,
                'dt' => 't',
                'q' => $text,
            ])
            ->throw()
            ->json();

        if (! isset($response[0]) || ! is_array($response[0])) {
            throw new RuntimeException('Google returned an unexpected translation response.');
        }

        $segments = [];
        foreach ($response[0] as $sentence) {
            if (isset($sentence[0]) && is_string($sentence[0])) {
                $segments[] = $sentence[0];
            }
        }

        return implode('', $segments);
    }

    private function translateWithLibreTranslate(
        string $url,
        string $text,
        string $targetLanguage,
        string $sourceLanguage,
    ): string {
        $payload = [
            'q' => $text,
            'source' => $sourceLanguage,
            'target' => $targetLanguage,
            'format' => 'text',
        ];
        $key = (string) config('services.translation.key');
        if ($key !== '') {
            $payload['api_key'] = $key;
        }

        $endpoint = str_ends_with($url, '/translate') ? $url : $url.'/translate';

        return (string) Http::acceptJson()
            ->asJson()
            ->timeout(15)
            ->post($endpoint, $payload)
            ->throw()
            ->json('translatedText');
    }
}
