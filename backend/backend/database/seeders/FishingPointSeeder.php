<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\FishingPoint;
class FishingPointSeeder extends Seeder {
  public function run(): void {
    $cats=['spot','shop','slip','resort'];
    for($i=1;$i<=120;$i++){
      FishingPoint::create([
        'title'=>"Demo {$cats[$i%4]} #$i",
        'description'=>'Демо-точка',
        'category'=>$cats[$i%4],
        'lat'=>55.75+(mt_rand(-300,300)/1000.0),
        'lng'=>37.62+(mt_rand(-500,500)/1000.0),
        'is_public'=>true,
        'is_highlighted'=>$i%11===0,
        'photo_url'=>null,
        'is_approved'=>true,
      ]);
    }
  }
}
