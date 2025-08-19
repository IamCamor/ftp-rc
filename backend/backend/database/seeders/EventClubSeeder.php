<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Event;
use App\Models\Club;
class EventClubSeeder extends Seeder {
  public function run(): void {
    for($i=1;$i<=40;$i++){
      Event::create([
        'title'=>"Соревнование #$i",'region'=>'RU-MOW',
        'starts_at'=>now()->addDays($i),'ends_at'=>now()->addDays($i+1),
        'description'=>"Описание события #$i",
        'location_lat'=>55.75+(mt_rand(-200,200)/1000.0),
        'location_lng'=>37.62+(mt_rand(-300,300)/1000.0),
        'link'=>"https://example.com/event/$i",'photo_url'=>null,'is_approved'=>true,
      ]);
    }
    for($i=1;$i<=40;$i++){
      Club::create([ 'name'=>"Клуб #$i",'region'=>'RU-MOW','description'=>"Описание клуба #$i",'logo_url'=>null,'is_approved'=>true ]);
    }
  }
}
