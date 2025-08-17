<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class S8SlugSeeder extends Seeder
{
    public function run(): void
    {
        $users = DB::table('users')->get();
        foreach ($users as $u) {
            if (!$u->slug) {
                $slug = Str::slug($u->name) ?: ('user-'.$u->id);
                $base = $slug; $i = 1;
                while (DB::table('users')->where('slug', $slug)->exists()) { $slug = $base.'-'.$i++; }
                DB::table('users')->where('id', $u->id)->update(['slug'=>$slug]);
            }
        }
    }
}
