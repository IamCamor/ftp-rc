<?php
namespace Database\Factories; use Illuminate\Database\Eloquent\Factories\Factory;
class MapPointFactory extends Factory { protected $model=\App\Models\MapPoint::class;
 public function definition(): array { $types=['spot','shop','slip','base','catch']; return ['title'=>$this->faker->city().' spot','description'=>$this->faker->sentence(),'lat'=>$this->faker->latitude(42.0,60.0),'lng'=>$this->faker->longitude(19.0,150.0),'type'=>$this->faker->randomElement($types),'is_featured'=>$this->faker->boolean(10),'visibility'=>'public']; } }