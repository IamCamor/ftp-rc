@php($title='События') @extends('admin.layout')
@section('content')
<h1 class="text-xl font-semibold mb-4">События</h1>
<form method="post" action="{{ route('admin.events.store') }}" class="mb-4 p-3 bg-white rounded-2xl shadow grid md:grid-cols-5 gap-2">
  @csrf
  <input name="title" placeholder="Название" class="border rounded px-2 py-1"/>
  <input name="starts_at" type="datetime-local" class="border rounded px-2 py-1"/>
  <input name="ends_at" type="datetime-local" class="border rounded px-2 py-1"/>
  <input name="region" placeholder="Регион" class="border rounded px-2 py-1"/>
  <input name="description" placeholder="Описание" class="border rounded px-2 py-1 md:col-span-5"/>
  <button class="px-3 py-1 rounded bg-indigo-600 text-white text-sm md:col-span-5">Создать</button>
</form>
<table class="w-full bg-white shadow rounded-2xl overflow-hidden">
<thead class="bg-slate-100 text-left"><tr><th class="p-2">ID</th><th class="p-2">Название</th><th class="p-2">Начало</th><th class="p-2">Регион</th><th class="p-2"></th></tr></thead>
<tbody>
@foreach($events as $e)
<tr class="border-t">
  <td class="p-2">{{ $e->id }}</td>
  <td class="p-2">{{ $e->title }}</td>
  <td class="p-2">{{ $e->starts_at }}</td>
  <td class="p-2">{{ $e->region }}</td>
  <td class="p-2 text-right">
    <form method="post" action="{{ route('admin.events.destroy', $e->id) }}">@csrf @method('delete')
      <button class="px-3 py-1 rounded bg-rose-600 text-white text-sm">Удалить</button>
    </form>
  </td>
</tr>
@endforeach
</tbody>
</table>
<div class="mt-3">{{ $events->links() }}</div>
@endsection
