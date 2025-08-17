@php($title='Уловы') @extends('admin.layout')
@section('content')
<h1 class="text-xl font-semibold mb-4">Уловы</h1>
<table class="w-full bg-white shadow rounded-2xl overflow-hidden">
<thead class="bg-slate-100 text-left"><tr><th class="p-2">ID</th><th class="p-2">Пользователь</th><th class="p-2">Вид</th><th class="p-2">Вес</th><th class="p-2">Дата</th><th class="p-2"></th></tr></thead>
<tbody>
@foreach($catches as $c)
<tr class="border-t">
  <td class="p-2">{{ $c->id }}</td>
  <td class="p-2">{{ $c->user_id }}</td>
  <td class="p-2">{{ $c->species }}</td>
  <td class="p-2">{{ $c->weight }}</td>
  <td class="p-2">{{ $c->created_at }}</td>
  <td class="p-2 text-right">
    <form method="post" action="{{ route('admin.catches.destroy', $c->id) }}">@csrf @method('delete')
      <button class="px-3 py-1 rounded bg-rose-600 text-white text-sm">Удалить</button>
    </form>
  </td>
</tr>
@endforeach
</tbody>
</table>
<div class="mt-3">{{ $catches->links() }}</div>
@endsection
