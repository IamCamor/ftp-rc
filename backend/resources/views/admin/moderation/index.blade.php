@php($title='Модерация') @extends('admin.layout')
@section('content')
<h1 class="text-xl font-semibold mb-4">Очередь модерации</h1>
<table class="w-full bg-white shadow rounded-2xl overflow-hidden">
<thead class="bg-slate-100 text-left"><tr><th class="p-2">ID</th><th class="p-2">Тип</th><th class="p-2">Ref</th><th class="p-2">Провайдер</th><th class="p-2">Статус</th><th class="p-2"></th></tr></thead>
<tbody>
@foreach($items as $m)
<tr class="border-t">
  <td class="p-2">{{ $m->id }}</td>
  <td class="p-2">{{ $m->type }}</td>
  <td class="p-2">{{ $m->ref_id }}</td>
  <td class="p-2">{{ $m->provider }}</td>
  <td class="p-2">{{ $m->status }}</td>
  <td class="p-2 text-right">
    <div class="flex gap-2 justify-end">
      <form method="post" action="{{ route('admin.moderation.approve', $m->id) }}">@csrf
        <button class="px-3 py-1 rounded bg-emerald-600 text-white text-sm">Одобрить</button>
      </form>
      <form method="post" action="{{ route('admin.moderation.reject', $m->id) }}">@csrf
        <button class="px-3 py-1 rounded bg-rose-600 text-white text-sm">Отклонить</button>
      </form>
    </div>
  </td>
</tr>
@endforeach
</tbody>
</table>
<div class="mt-3">{{ $items->links() }}</div>
@endsection
