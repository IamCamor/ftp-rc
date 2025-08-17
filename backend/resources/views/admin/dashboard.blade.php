@php($title='Панель') @extends('admin.layout')
@section('content')
<div class="grid grid-cols-2 md:grid-cols-5 gap-3">
  <div class="p-4 rounded-2xl bg-white shadow"><div class="text-sm opacity-60">Пользователи</div><div class="text-2xl font-bold">{{ $stats['users'] }}</div></div>
  <div class="p-4 rounded-2xl bg-white shadow"><div class="text-sm opacity-60">Точки</div><div class="text-2xl font-bold">{{ $stats['points'] }}</div></div>
  <div class="p-4 rounded-2xl bg-white shadow"><div class="text-sm opacity-60">Уловы</div><div class="text-2xl font-bold">{{ $stats['catches'] }}</div></div>
  <div class="p-4 rounded-2xl bg-white shadow"><div class="text-sm opacity-60">События</div><div class="text-2xl font-bold">{{ $stats['events'] }}</div></div>
  <div class="p-4 rounded-2xl bg-white shadow"><div class="text-sm opacity-60">Клубы</div><div class="text-2xl font-bold">{{ $stats['clubs'] }}</div></div>
</div>
@endsection
