<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\User;
class AdminSeeder extends Seeder {
  public function run(): void {
    $email=env('ADMIN_EMAIL','admin@fishtrackpro.local'); $pass=env('ADMIN_PASSWORD','admin123');
    if (class_exists(User::class)) {
      User::updateOrCreate(['email'=>$email],[ 'name'=>'Admin','password'=>Hash::make($pass),'remember_token'=>Str::random(10) ]);
    }
  }
}
