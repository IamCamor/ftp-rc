@extends('layouts.admin')
@section('content')
<div class="card"><h3>Точки</h3>
<table>
<tr><th>ID</th><th>Заголовок</th><th>Категория</th><th>Статус</th><th>Фото</th><th>Действие</th></tr>
@foreach($items as $p)
<tr>
  <td>#{{ $p->id }}</td>
  <td>{{ $p->title }}</td>
  <td>{{ $p->category }}</td>
  <td><span class="badge">{{ $p->status }}</span></td>
  <td>@if($p->photo_url)<img src="{{ $p->photo_url }}" style="height:60px;border-radius:8px"/>@endif</td>
  <td>
    <form method="post" action="/admin/points/{{ $p->id }}/approve">@csrf<button class="btn">Одобрить</button></form>
    <form method="post" action="/admin/points/{{ $p->id }}/reject" style="display:inline">@csrf<button class="btn warn">Отклонить</button></form>
  </td>
</tr>
@endforeach
</table>
</div>
@endsection
