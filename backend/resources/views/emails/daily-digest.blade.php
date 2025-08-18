<!doctype html><html><body style="font-family:system-ui">
  <h2>Дайджест уведомлений</h2>
  <ul>
    @foreach($items as $i)
      <li><strong>{{ $i->type }}</strong> — {{ $i->title ?? '' }} ({{ $i->created_at }})</li>
    @endforeach
  </ul>
  <hr><p>FishTrackPro</p>
</body></html>
