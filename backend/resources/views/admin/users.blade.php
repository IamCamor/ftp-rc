@extends('layouts.admin')
@section('content')
<div class="card"><h3>Пользователи и роли</h3>
<table>
<tr><th>ID</th><th>Имя</th><th>Email</th><th>Роль</th><th>Назначить</th></tr>
@foreach($items as $u)
<tr>
  <td>#{{ $u->id }}</td>
  <td>{{ $u->name }}</td>
  <td>{{ $u->email }}</td>
  <td>
    @php
      $r = DB::table('user_roles')->join('roles','roles.id','=','user_roles.role_id')->where('user_roles.user_id',$u->id)->pluck('roles.name')->implode(', ');
    @endphp
    {{ $r ?: '—' }}
  </td>
  <td>
    <form method="post" action="/admin/users/{{ $u->id }}/role">@csrf
      <select name="role">
        @foreach($roles as $role)
          <option value="{{ $role->name }}">{{ $role->name }}</option>
        @endforeach
      </select>
      <button class="btn">Назначить</button>
    </form>
  </td>
</tr>
@endforeach
</table>
</div>
@endsection
