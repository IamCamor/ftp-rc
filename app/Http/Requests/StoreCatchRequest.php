<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCatchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool)$this->user();
    }

    public function rules(): array
    {
        return [
            'lat' => ['required','numeric','between:-90,90'],
            'lng' => ['required','numeric','between:-180,180'],
            'species' => ['nullable','string','max:255'],
            'length' => ['nullable','numeric'],
            'weight' => ['nullable','numeric'],
            'depth' => ['nullable','numeric'],
            'style' => ['nullable','string','max:255'],
            'lure' => ['nullable','string','max:255'],
            'tackle' => ['nullable','string','max:255'],
            'privacy' => ['required','in:all,friends'],
            'caught_at' => ['nullable','date'],
            'water_type' => ['nullable','string','max:255'],
            'water_temp' => ['nullable','numeric'],
            'wind_speed' => ['nullable','numeric'],
            'pressure' => ['nullable','numeric'],
            'companions' => ['nullable','string','max:255'],
            'notes' => ['nullable','string'],
            'photo' => ['nullable','file','image','max:8192'],
            'photo_url' => ['nullable','string','max:255'],
        ];
    }
}
