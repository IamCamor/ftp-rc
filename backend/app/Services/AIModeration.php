<?php
namespace App\Services;

use Illuminate\Support\Facades\Log;

class AIModeration
{
    public function moderateText(string $text): array
    {
        $enabled = (bool) config('app_ui.features.ai_moderation', false);
        if (!$enabled) {
            return ['ok' => true, 'provider' => 'disabled', 'score' => 0.0, 'labels' => []];
        }

        // Short text fast-path
        $clean = trim($text);
        if ($clean === '') {
            return ['ok' => true, 'provider' => 'empty', 'score' => 0.0, 'labels' => []];
        }

        $provider = config('app_ui.features.ai_provider', 'auto');
        $threshold = (float) config('app_ui.features.ai_threshold', 0.6);

        // Try OpenAI first (if auto) else pick explicit
        if ($provider === 'openai' or $provider === 'auto') {
            $res = $this->openaiModerate($clean);
            if ($res['status'] === 'ok') {
                return [
                    'ok' => $res['score'] < $threshold,
                    'provider' => 'openai',
                    'score' => $res['score'],
                    'labels' => $res['labels'],
                ];
            }
        }

        // Try Yandex
        if ($provider === 'yandex' or $provider === 'auto') {
            $res = $this->yandexClassify($clean);
            if ($res['status'] === 'ok') {
                return [
                    'ok' => $res['score'] < $threshold,
                    'provider' => 'yandex',
                    'score' => $res['score'],
                    'labels' => $res['labels'],
                ];
            }
        }

        // Fallback: pass through but log
        Log::warning('AI moderation fallback pass', ['reason' => 'no_provider_or_error']);
        return ['ok' => true, 'provider' => 'fallback', 'score' => 0.0, 'labels' => []];
    }

    private function openaiModerate(string $text): array
    {
        $key = config('app_ui.providers.openai.api_key', '');
        $base = rtrim(config('app_ui.providers.openai.base', 'https://api.openai.com/v1'), '/');
        $model = config('app_ui.providers.openai.model', 'omni-moderation-latest');
        if ($key === '') return ['status' => 'no_key'];

        $url = $base . '/moderations';
        $payload = json_encode([
            'model' => $model,
            'input' => $text,
        ]);

        try {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json',
                    'Authorization: Bearer ' . $key,
                ],
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => $payload,
                CURLOPT_TIMEOUT => 10,
            ]);
            $body = curl_exec($ch);
            if ($body === false) {
                return ['status' => 'curl_error', 'error' => curl_error($ch)];
            }
            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            $json = json_decode($body, true);
            if (!is_array($json) || $code >= 400) {
                return ['status' => 'http_error', 'code' => $code, 'body' => $body];
            }
            // Map OpenAI response to score (simple heuristic)
            // If flagged true, set score=1.0, else 0.
            $res = $json['results'][0] ?? null;
            if (!$res) return ['status' => 'parse_error'];
            $flagged = (bool)($res['flagged'] ?? false);
            $categories = array_keys(array_filter($res['categories'] ?? []));
            $score = $flagged ? 1.0 : 0.0;
            return ['status' => 'ok', 'score' => $score, 'labels' => $categories];
        } catch (\Throwable $e) {
            return ['status' => 'exception', 'error' => $e->getMessage()];
        }
    }

    private function yandexClassify(string $text): array
    {
        $key = config('app_ui.providers.yandex.api_key', '');
        $folderId = config('app_ui.providers.yandex.folder_id', '');
        $endpoint = config('app_ui.providers.yandex.endpoint', '');
        $model = config('app_ui.providers.yandex.model', 'yandexgpt-lite');
        if ($key === '' || $endpoint === '') return ['status' => 'no_key'];

        // Prompt with a simple safe-classifier instruction
        $system = "Ты модератор. Верни JSON {\"score\": number 0..1, \"labels\": string[]} — score ближе к 1 если есть токсичность, оскорбления, спам.";
        $prompt = $system . "\nТекст: " . $text;

        $payload = json_encode([
            'modelUri' => "gpt://" . $folderId . "/" . $model,
            'completionOptions' => [
                'stream' => False,
                'temperature' => 0,
                'maxTokens' => 200,
            ],
            'messages' => [
                ['role' => 'system', 'text' => $system],
                ['role' => 'user', 'text' => 'Оцени и верни JSON результат без лишнего текста. Текст: ' . $text],
            ],
        ]);

        try {
            $ch = curl_init($endpoint . ':complete');
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json',
                    'Authorization: Api-Key ' . $key,
                    'x-folder-id: ' . $folderId,
                ],
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => $payload,
                CURLOPT_TIMEOUT => 12,
            ]);
            $body = curl_exec($ch);
            if ($body === false) {
                return ['status' => 'curl_error', 'error' => curl_error($ch)];
            }
            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            $json = json_decode($body, true);
            if (!is_array($json) || $code >= 400) {
                return ['status' => 'http_error', 'code' => $code, 'body' => $body];
            }
            // Yandex response parsing (best-effort)
            $textOut = $json['result']['alternatives'][0]['message']['text'] ?? '';
            $parsed = json_decode($textOut, true);
            if (!is_array($parsed)) {
                return ['status' => 'parse_error', 'raw' => $textOut];
            }
            $score = (float)($parsed['score'] ?? 0.0);
            $labels = (array)($parsed['labels'] ?? []);
            return ['status' => 'ok', 'score' => $score, 'labels' => $labels];
        } catch (\Throwable $e) {
            return ['status' => 'exception', 'error' => $e->getMessage()];
        }
    }
}
