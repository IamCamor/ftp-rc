<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;

class ConfigController extends Controller {
  public function ui(){
    return response()->json([
      'brand'=>[
        'logoPath'=> config('ui.logo'),
        'bgPatternPath'=> config('ui.bg'),
        'primary'=> config('ui.primary'),
        'secondary'=> config('ui.secondary'),
        'glass'=> [
          'opacity'=> (float) config('ui.glass.opacity'),
          'blur'=> (int) config('ui.glass.blur'),
          'saturation'=> (int) config('ui.glass.saturation'),
        ]
      ],
      'features'=>[
        'i18n'=> (bool) config('features.i18n', true),
        'themes'=> (bool) config('features.themes', true),
        'ar_mode'=> (bool) config('features.ar_mode', true),
        'weather'=> (bool) config('features.weather', true),
        'payments'=> (bool) config('features.payments', true),
        'banners'=> (bool) config('features.banners', true),
      ],
      'i18n'=>[
        'default'=> env('I18N_DEFAULT','en'),
        'langs'=> explode(',', env('I18N_LANGS','en,ru'))
      ]
    ]);
  }
}
