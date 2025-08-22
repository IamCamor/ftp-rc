<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function handleAvailable(Request $r)
    {
        $handle = (string) $r->query('handle', '');
        $exists = \DB::table('users')->where('handle', $handle)->exists();
        return response()->json(['available' => !$exists && $handle !== '']);
    }

    public function setup(Request $r)
    {
        $user = $r->user();

        $data = $r->validate([
            'name'   => ['required','string','max:255'],
            'handle' => ['required','string','max:64', Rule::unique('users','handle')->ignore($user->id)],
            'dob'    => ['nullable','date'],
            'bio'    => ['nullable','string','max:2000'],
            'links.instagram' => ['nullable','string','max:255'],
            'links.vk'        => ['nullable','string','max:255'],
            'links.telegram'  => ['nullable','string','max:255'],
            'links.website'   => ['nullable','string','max:255'],
            'avatar' => ['nullable','image','max:4096'],
        ]);

        if ($r->hasFile('avatar')) {
            $path = $r->file('avatar')->store('avatars', 'public'); // storage/app/public/avatars
            $user->avatar_path = $path;
        }

        $user->name   = $data['name'];
        $user->handle = $data['handle'];
        $user->dob    = $data['dob'] ?? null;
        $user->bio    = $data['bio'] ?? null;

        $links = [
            'instagram' => data_get($data, 'links.instagram'),
            'vk'        => data_get($data, 'links.vk'),
            'telegram'  => data_get($data, 'links.telegram'),
            'website'   => data_get($data, 'links.website'),
        ];
        // убираем пустые
        $links = array_filter($links, fn($v) => filled($v));
        $user->links = $links ? json_encode($links, JSON_UNESCAPED_UNICODE) : null;

        $user->save();

        return response()->json(['ok' => true]);
    }

    public function uploadAvatar(Request $r)
    {
        $r->validate(['avatar' => ['required','image','max:4096']]);
        $path = $r->file('avatar')->store('avatars', 'public');
        $u = $r->user();
        $u->avatar_path = $path;
        $u->save();

        return response()->json(['avatar' => url('/storage/'.$path)]);
    }
}
