import { useState } from 'react';
import { createCatch } from '../api/api';

export default function AddCatchForm() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>('');
  const [ok, setOk] = useState<string>('');

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true); setError(''); setOk('');
    const form = new FormData(e.currentTarget);
    try {
      await createCatch(form);
      setOk('Улов добавлен!');
      e.currentTarget.reset();
    } catch (e:any) {
      console.error(e);
      setError('Ошибка при добавлении улова');
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="p-4 space-y-3 max-w-2xl">
      {error && <div className="text-red-600">{error}</div>}
      {ok && <div className="text-green-700">{ok}</div>}

      <div className="grid grid-cols-2 gap-3">
        <label className="flex flex-col">
          <span>Широта (lat)*</span>
          <input name="lat" type="number" step="any" required className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Долгота (lng)*</span>
          <input name="lng" type="number" step="any" required className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Вид рыбы (species)</span>
          <input name="species" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Длина (length, см)</span>
          <input name="length" type="number" step="any" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Вес (weight, кг)</span>
          <input name="weight" type="number" step="any" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Глубина (depth, м)</span>
          <input name="depth" type="number" step="any" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Метод (style)</span>
          <input name="style" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Приманка (lure)</span>
          <input name="lure" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Снасть (tackle)</span>
          <input name="tackle" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Приватность*</span>
          <select name="privacy" required className="border rounded p-2">
            <option value="all">all</option>
            <option value="friends">friends</option>
          </select>
        </label>

        <label className="flex flex-col">
          <span>Тип воды (water_type)</span>
          <input name="water_type" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Температура воды (°C)</span>
          <input name="water_temp" type="number" step="any" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Скорость ветра (м/с)</span>
          <input name="wind_speed" type="number" step="any" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Давление (hPa)</span>
          <input name="pressure" type="number" step="any" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Компаньоны</span>
          <input name="companions" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Дата/время поимки</span>
          <input name="caught_at" type="datetime-local" className="border rounded p-2" />
        </label>
      </div>

      <label className="flex flex-col">
        <span>Заметки</span>
        <textarea name="notes" className="border rounded p-2" rows={3} />
      </label>

      <div className="grid grid-cols-2 gap-3">
        <label className="flex flex-col">
          <span>Фото (файл)</span>
          <input name="photo" type="file" accept="image/*" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Или ссылка на фото (photo_url)</span>
          <input name="photo_url" className="border rounded p-2" />
        </label>
      </div>

      <button className="px-4 py-2 rounded bg-blue-600 text-white">
        Добавить улов
      </button>
    </form>
  );
}
