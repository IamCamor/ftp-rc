<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        if (!DB::table('roles')->where('name','admin')->exists()) {
            DB::table('roles')->insert(['name'=>'admin', 'created_at'=>now(), 'updated_at'=>now()]);
        }
        $user = DB::table('users')->where('email','admin@fishtrackpro.local')->first();
        if (!$user) {
            DB::table('users')->insert([
                'name'=>'Admin', 'email'=>'admin@fishtrackpro.local', 'password'=>bcrypt('admin123'),
                'slug'=>'admin', 'created_at'=>now(),'updated_at'=>now()
            ]);
            $user = DB::table('users')->where('email','admin@fishtrackpro.local')->first();
        }
        $roleId = DB::table('roles')->where('name','admin')->value('id');
        if ($roleId && !DB::table('user_roles')->where('user_id',$user->id)->where('role_id',$roleId)->exists()) {
            DB::table('user_roles')->insert(['user_id'=>$user->id, 'role_id'=>$roleId]);
        }
    }
}
