import React, { useState } from 'react';
import { addCatch } from '../api';

const AddCatchPage: React.FC = () => {
  const [form, setForm] = useState<any>({
    species:'', length:'', weight:'',
    style:'', lure:'', tackle:'', notes:'',
    photo_url:'', lat:'', lng:'', caught_at:'', privacy:'all'
  });
  const [msg, setMsg] = useState('');

  function set<K extends string>(k:K, v:any){ setForm((s:any)=> ({...s, [k]:v})); }

  async function submit(e:React.FormEvent){
    e.preventDefault(); setMsg('');
    try{
      const payload = {
        ...form,
        length: form.length? Number(form.length): undefined,
        weight: form.weight? Number(form.weight): undefined,
        lat: form.lat? Number(form.lat): undefined,
        lng: form.lng? Number(form.lng): undefined,
        caught_at: form.caught_at ? new Date(form.caught_at).toISOString() : undefined,
      };
      await addCatch(payload);
      setMsg('Улов добавлен');
    }catch(ex:any){ setMsg(ex?.message || 'Ошибка сохранения'); }
  }

  return (
    <div className="container">
      <h2 className="h2">Добавить улов</h2>
      <form className="glass card grid" onSubmit={submit}>
        <input className="input" placeholder="Вид рыбы" value={form.species} onChange={e=>set('species', e.target.value)} />
        <div className="row" style={{gap:8}}>
          <input className="input" placeholder="Длина (см)" value={form.length} onChange={e=>set('length', e.target.value)} />
          <input className="input" placeholder="Вес (кг)" value={form.weight} onChange={e=>set('weight', e.target.value)} />
        </div>
        <div className="row" style={{gap:8}}>
          <input className="input" placeholder="Стиль" value={form.style} onChange={e=>set('style', e.target.value)} />
          <input className="input" placeholder="Приманка" value={form.lure} onChange={e=>set('lure', e.target.value)} />
          <input className="input" placeholder="Снасти" value={form.tackle} onChange={e=>set('tackle', e.target.value)} />
        </div>
        <textarea className="textarea" placeholder="Заметки" value={form.notes} onChange={e=>set('notes', e.target.value)} />
        <input className="input" placeholder="URL фото" value={form.photo_url} onChange={e=>set('photo_url', e.target.value)} />

        <div className="row" style={{gap:8}}>
          <input className="input" placeholder="Широта" value={form.lat} onChange={e=>set('lat', e.target.value)} />
          <input className="input" placeholder="Долгота" value={form.lng} onChange={e=>set('lng', e.target.value)} />
        </div>

        <label className="muted">Дата/время по местному времени (ISO будет сформирован автоматически)</label>
        <input className="input" type="datetime-local" value={form.caught_at} onChange={e=>set('caught_at', e.target.value)} />

        <select className="select" value={form.privacy} onChange={e=>set('privacy', e.target.value)}>
          <option value="all">Все</option>
          <option value="friends">Друзья</option>
          <option value="private">Лично</option>
        </select>

        <button className="btn primary" type="submit">Сохранить</button>
        {msg && <div className="muted">{msg}</div>}
      </form>
    </div>
  );
};
export default AddCatchPage;
