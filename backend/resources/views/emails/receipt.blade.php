<!doctype html><html><body>
<h2>Квитанция FishTrackPro</h2>
<p>Спасибо за оплату плана: <b>{{ $data['plan'] ?? 'Pro' }}</b></p>
<p>Сумма: {{ $data['amount'] ?? '—' }} {{ $data['currency'] ?? 'RUB' }}</p>
<p>Номер платежа: {{ $data['payment_id'] ?? '—' }}</p>
</body></html>
