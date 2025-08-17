@extends('layouts.admin')
@section('content')
<div class="card"><h3>Комментарии</h3>
<table>
<tr><th>ID</th><th>Текст</th><th>Статус</th><th>Действие</th></tr>
@foreach($items as $c)
<tr>
  <td>#{{ $c->id }}</td>
  <td>{{ $c->body }}</td>
  <td>{!! $c->is_approved ? '<span class="badge">approved</span>' : '<span class="badge">pending</span>' !!}</td>
  <td>
    <form method="post" action="/admin/comments/{{ $c->id }}/approve">@csrf<button class="btn">Одобрить</button></form>
    <form method="post" action="/admin/comments/{{ $c->id }}/reject" style="display:inline">@csrf<button class="btn warn">Отклонить</button></form>
  </td>
</tr>
@endforeach
</table>
</div>
@endsection
