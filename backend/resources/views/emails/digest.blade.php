<!doctype html><html><body style="font-family:Arial,sans-serif">
<h2>Дайджест FishTrackPro</h2>
<p>Новые уловы: {{ $data['catches'] ?? 0 }}</p>
<p>Новые комментарии: {{ $data['comments'] ?? 0 }}</p>
<p>События на этой неделе: {{ $data['events'] ?? 0 }}</p>
<hr><small>Вы получили это письмо, потому что подписаны на уведомления в FishTrackPro.</small>
</body></html>
