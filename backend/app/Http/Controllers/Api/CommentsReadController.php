<?php
namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CommentsReadController extends Controller
{
    public function index($catchId)
    {
        $q = DB::table('catch_comments as cc')
            ->leftJoin('users as u','u.id','=','cc.user_id')
            ->selectRaw('cc.id, cc.user_id, u.name as user_name, u.avatar_url as user_avatar_url, cc.body, cc.created_at')
            ->where('cc.catch_id', $catchId);

        if (Schema::hasColumn('catch_comments','is_approved')) {
            $q->where('cc.is_approved', 1);
        }
        $q->orderByDesc('cc.id');

        // Возвращаем простой массив или пагинацию — фронту без разницы
        return response()->json(['items'=>$q->limit(100)->get()]);
    }
}
