@php($title='Пользователи') @extends('admin.layout')
@section('content')
<h1 class="text-xl font-semibold mb-4">Пользователи</h1>
<table class="w-full bg-white shadow rounded-2xl overflow-hidden">
<thead class="bg-slate-100 text-left"><tr><th class="p-2">ID</th><th class="p-2">Имя</th><th class="p-2">Email</th><th class="p-2">Админ</th><th class="p-2"></th></tr></thead>
<tbody>
@foreach($users as $u)
<tr class="border-t">
  <td class="p-2">{{ $u->id }}</td>
  <td class="p-2">{{ $u->name }}</td>
  <td class="p-2">{{ $u->email }}</td>
  <td class="p-2">{{ $u->is_admin ? 'Да' : 'Нет' }}</td>
  <td class="p-2 text-right">
    <form method="post" action="{{ route('admin.users.toggleAdmin', $u->id) }}">@csrf
      <button class="px-3 py-1 rounded bg-indigo-600 text-white text-sm">Toggle Admin</button>
    </form>
  </td>
</tr>
@endforeach
</tbody>
</table>
<div class="mt-3">{{ $users->links() }}</div>
@endsection
