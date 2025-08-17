@php($title='Баннеры') @extends('admin.layout')
@section('content')
<h1 class="text-xl font-semibold mb-4">Баннерные слоты</h1>
<form method="post" action="{{ route('admin.banners.slot.store') }}" class="mb-4 p-3 bg-white rounded-2xl shadow flex gap-2">
  @csrf
  <input name="code" placeholder="код слота (header)" class="border rounded px-2 py-1 grow"/>
  <input name="title" placeholder="название" class="border rounded px-2 py-1 grow"/>
  <button class="px-3 py-1 rounded bg-indigo-600 text-white text-sm">Добавить слот</button>
</form>
@foreach($slots as $slot)
<div class="mb-6 p-4 bg-white rounded-2xl shadow">
  <div class="font-semibold mb-2">{{ $slot->code }} — {{ $slot->title }}</div>
  <form method="post" action="{{ route('admin.banners.store') }}" class="flex gap-2 items-center">
    @csrf
    <input type="hidden" name="slot_id" value="{{ $slot->id }}"/>
    <input name="title" placeholder="заголовок" class="border rounded px-2 py-1 grow"/>
    <input name="image" placeholder="image url (опц.)" class="border rounded px-2 py-1 grow"/>
    <input name="link" placeholder="link url (опц.)" class="border rounded px-2 py-1 grow"/>
    <button class="px-3 py-1 rounded bg-emerald-600 text-white text-sm">Добавить баннер</button>
  </form>
  <div class="mt-3 space-y-2">
    @foreach($slot->banners as $b)
    <div class="flex justify-between items-center border rounded px-2 py-1">
      <div><div class="font-medium">{{ $b->title }}</div><div class="text-sm opacity-60">{{ $b->image }} | {{ $b->link }}</div></div>
      <form method="post" action="{{ route('admin.banners.destroy', $b->id) }}">@csrf @method('delete')
        <button class="px-3 py-1 rounded bg-rose-600 text-white text-sm">Удалить</button>
      </form>
    </div>
    @endforeach
  </div>
</div>
@endforeach
@endsection
