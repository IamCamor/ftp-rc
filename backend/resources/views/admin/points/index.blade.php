@php($title='Точки') @extends('admin.layout')
@section('content')
<h1 class="text-xl font-semibold mb-4">Точки на карте</h1>
<table class="w-full bg-white shadow rounded-2xl overflow-hidden">
<thead class="bg-slate-100 text-left"><tr><th class="p-2">ID</th><th class="p-2">Название</th><th class="p-2">Тип</th><th class="p-2">Коорд.</th><th class="p-2">Избран.</th><th class="p-2"></th></tr></thead>
<tbody>
@foreach($points as $p)
<tr class="border-t">
  <td class="p-2">{{ $p->id }}</td>
  <td class="p-2">{{ $p->title }}</td>
  <td class="p-2">{{ $p->type }}</td>
  <td class="p-2">{{ $p->lat }}, {{ $p->lng }}</td>
  <td class="p-2">{{ $p->is_featured ? 'Да' : 'Нет' }}</td>
  <td class="p-2 text-right">
    <div class="flex gap-2 justify-end">
      <form method="post" action="{{ route('admin.points.feature', $p->id) }}">@csrf
        <button class="px-3 py-1 rounded bg-amber-600 text-white text-sm">Feature</button>
      </form>
      <form method="post" action="{{ route('admin.points.destroy', $p->id) }}">@csrf @method('delete')
        <button class="px-3 py-1 rounded bg-rose-600 text-white text-sm">Удалить</button>
      </form>
    </div>
  </td>
</tr>
@endforeach
</tbody>
</table>
<div class="mt-3">{{ $points->links() }}</div>
@endsection
