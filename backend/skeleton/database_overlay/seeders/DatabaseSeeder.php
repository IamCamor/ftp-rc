<?php
namespace Database\Seeders; use Illuminate\Database\Seeder; use App\Models\User; use App\Models\MapPoint; use App\Models\CatchRecord; use Illuminate\Support\Facades\Hash;
class DatabaseSeeder extends Seeder {
  public function run(): void {
    User::factory()->create(['name'=>'Demo Admin','email'=>'demo@fishtrackpro.ru','password'=>Hash::make('password'),'is_admin'=>true]);
    User::factory(9)->create();
    MapPoint::factory()->create(['title'=>'Demo Spot Moscow','description'=>'Public demo point','lat'=>55.751244,'lng'=>37.618423,'type'=>'spot','is_featured'=>true,'visibility'=>'public']);
    MapPoint::factory(40)->create();
    CatchRecord::factory(50)->create();
  }
}