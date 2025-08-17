<!doctype html>
<html lang="ru"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Админка — FishTrackPro</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
<style>
body{ font-family:Inter,system-ui,Segoe UI,Roboto,Arial,sans-serif; margin:0; background:#0b1020; color:#e8eaf2; }
a{ color:#a6c8ff; text-decoration:none; }
.header{ position:sticky; top:0; backdrop-filter:saturate(180%) blur(14px); background:rgba(15,20,40,.6); border-bottom:1px solid rgba(255,255,255,.08); }
.container{ max-width:1100px; margin:0 auto; padding:16px; }
.card{ background:linear-gradient(180deg, rgba(255,255,255,.08), rgba(255,255,255,.04)); border:1px solid rgba(255,255,255,.1); border-radius:16px; padding:16px; margin:16px 0; box-shadow:0 10px 30px rgba(0,0,0,.25); }
.btn{ background:#2e6ff2; color:white; border:none; padding:8px 14px; border-radius:10px; cursor:pointer; }
.btn.warn{ background:#d97706; }
.badge{ display:inline-block; padding:2px 8px; border-radius:999px; background:rgba(255,255,255,.12); margin-left:6px; font-size:12px; }
table{ width:100%; border-collapse:collapse; }
th,td{ padding:8px 10px; border-bottom:1px dashed rgba(255,255,255,.12); }
input,select{ background:rgba(255,255,255,.08); border:1px solid rgba(255,255,255,.12); color:#e8eaf2; border-radius:10px; padding:6px 8px; }
</style>
</head><body>
<div class="header"><div class="container"><b>FishTrackPro • Admin</b> &nbsp; <a href="/admin">Главная</a> · <a href="/admin/comments">Комментарии</a> · <a href="/admin/points">Точки</a> · <a href="/admin/users">Пользователи</a></div></div>
<div class="container">@yield('content')</div>
</body></html>
