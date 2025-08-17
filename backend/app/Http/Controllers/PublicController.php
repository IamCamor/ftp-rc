<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Response;
use Illuminate\Support\Facades\DB;

class PublicController extends Controller
{
    public function robots()
    {
        $txt = "User-agent: *\nAllow: /\nSitemap: " . url('/sitemap.xml') . "\n";
        return Response::make($txt, 200, ['Content-Type'=>'text/plain']);
    }

    public function sitemap()
    {
        $base = url('/');
        $users = DB::table('users')->select('id','name','slug','updated_at')->limit(1000)->get();
        $catches = DB::table('catch_records')->select('id','updated_at')->limit(2000)->get();
        $xml = '<?xml version="1.0" encoding="UTF-8"?>';
        $xml .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';
        $xml .= '<url><loc>'.$base.'</loc><changefreq>daily</changefreq><priority>0.8</priority></url>';
        foreach ($users as $u) { $loc = $base . '/u/' . ($u->slug ?: $u->id); $xml .= '<url><loc>'.$loc.'</loc><changefreq>weekly</changefreq><priority>0.6</priority></url>'; }
        foreach ($catches as $c) { $loc = $base . '/c/' . $c->id; $xml .= '<url><loc>'.$loc.'</loc><changefreq>weekly</changefreq><priority>0.5</priority></url>'; }
        $xml .= '</urlset>';
        return Response::make($xml, 200, ['Content-Type'=>'application/xml']);
    }
}
