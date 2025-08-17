@php($title='Клубы') @extends('admin.layout')
@section('content')
<h1 class="text-xl font-semibold mb-4">Клубы</h1>
<table class="w-full bg-white shadow rounded-2xl overflow-hidden">
<thead class="bg-slate-100 text-left"><tr><th class="p-2">ID</th><th class="p-2">Название</th><th class="p-2">Участники</th><th class="p-2"></th></tr></thead>
<tbody>
@foreach($clubs as $c)
<tr class="border-t">
  <td class="p-2">{{ $c->id }}</td>
  <td class="p-2">{{ $c->name }}</td>
  <td class="p-2">{{ $c->members_count }}</td>
  <td class="p-2 text-right">
    <form method="post" action="{{ route('admin.clubs.destroy', $c->id) }}">@csrf @method('delete')
      <button class="px-3 py-1 rounded bg-rose-600 text-white text-sm">Удалить</button>
    </form>
  </td>
</tr>
@endforeach
</tbody>
</table>
<div class="mt-3">{{ $clubs->links() }}</div>
@endsection
