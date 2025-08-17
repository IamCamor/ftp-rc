<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ $title ?? 'Admin' }} — FishTrackPro</title>
<script src="https://cdn.tailwindcss.com"></script>
<script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="bg-slate-50 text-slate-900">
<nav class="bg-white/70 backdrop-blur border-b sticky top-0 z-10">
  <div class="max-w-6xl mx-auto px-4 h-14 flex items-center gap-4">
    <a href="{{ route('admin.dashboard') }}" class="font-semibold">Admin</a>
    <a href="{{ route('admin.users') }}" class="hover:underline">Пользователи</a>
    <a href="{{ route('admin.points') }}" class="hover:underline">Точки</a>
    <a href="{{ route('admin.catches') }}" class="hover:underline">Уловы</a>
    <a href="{{ route('admin.events') }}" class="hover:underline">События</a>
    <a href="{{ route('admin.clubs') }}" class="hover:underline">Клубы</a>
    <a href="{{ route('admin.banners') }}" class="hover:underline">Баннеры</a>
    <a href="{{ route('admin.moderation') }}" class="hover:underline">Модерация</a>
    <div class="ml-auto text-sm opacity-70">{{ auth()->user()->email ?? '' }}</div>
  </div>
</nav>
<main class="max-w-6xl mx-auto p-4">
  @if (session('ok'))
    <div class="mb-3 p-3 bg-green-100 border border-green-300 rounded">{{ session('ok') }}</div>
  @endif
  {{ $slot ?? '' }}
  @yield('content')
</main>
</body>
</html>
