<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class CatchResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $avatarUrl = '';
        if (!empty($this->user_avatar_path)) {
            $avatarUrl = preg_match('#^https?://#', $this->user_avatar_path)
                ? $this->user_avatar_path
                : Storage::disk('public')->url($this->user_avatar_path);
        }

        $mediaUrl = '';
        if (!empty($this->photo_url)) {
            $mediaUrl = preg_match('#^https?://#', $this->photo_url)
                ? $this->photo_url
                : Storage::disk('public')->url($this->photo_url);
        }

        return [
            'id' => (int)$this->id,
            'user_id' => (int)$this->user_id,
            'user_name' => (string)($this->user_name ?? ''),
            'user_avatar' => $avatarUrl,
            'lat' => (float)$this->lat,
            'lng' => (float)$this->lng,
            'species' => (string)($this->species ?? ''),
            'length' => is_null($this->length) ? null : (float)$this->length,
            'weight' => is_null($this->weight) ? null : (float)$this->weight,
            'depth' => is_null($this->depth) ? null : (float)$this->depth,
            'method' => (string)($this->style ?? ''),
            'bait' => (string)($this->lure ?? ''),
            'gear' => (string)($this->tackle ?? ''),
            'water_type' => (string)($this->water_type ?? ''),
            'water_temp' => is_null($this->water_temp) ? null : (float)$this->water_temp,
            'wind_speed' => is_null($this->wind_speed) ? null : (float)$this->wind_speed,
            'pressure' => is_null($this->pressure) ? null : (float)$this->pressure,
            'companions' => (string)($this->companions ?? ''),
            'caption' => (string)($this->notes ?? ''),
            'media_url' => $mediaUrl,
            'privacy' => (string)($this->privacy ?? 'all'),
            'caught_at' => $this->caught_at ? $this->caught_at : null,
            'created_at' => $this->created_at,
            'likes_count' => (int)($this->likes_count ?? 0),
            'comments_count' => (int)($this->comments_count ?? 0),
            'liked_by_me' => (bool)($this->liked_by_me ?? false),
        ];
    }
}
