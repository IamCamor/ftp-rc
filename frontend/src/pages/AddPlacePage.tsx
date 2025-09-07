import React, { useState } from 'react';
import { addPlace } from '../api';

const AddPlacePage: React.FC = () => {
  const [form, setForm] = useState<any>({ title:'', description:'', lat:'', lng:'', photos:'' });
  const [msg, setMsg] = useState('');

  function set<K extends string>(k:K, v:any){ setForm((s:any)=> ({...s, [k]:v})); }

  async function submit(e:React.FormEvent){
    e.preventDefault(); setMsg('');
    try{
      const payload = {
        title: form.title,
        description: form.description || undefined,
        lat: Number(form.lat),
        lng: Number(form.lng),
        photos: form.photos ? form.photos.split(',').map((s:string)=>s.trim()).filter(Boolean) : undefined,
      };
      await addPlace(payload);
      setMsg('Место добавлено');
    }catch(ex:any){ setMsg(ex?.message || 'Ошибка сохранения'); }
  }

  return (
    <div className="container">
      <h2 className="h2">Добавить место</h2>
      <form className="glass card grid" onSubmit={submit}>
        <input className="input" placeholder="Название" value={form.title} onChange={e=>set('title', e.target.value)} required />
        <textarea className="textarea" placeholder="Описание" value={form.description} onChange={e=>set('description', e.target.value)} />
        <div className="row" style={{gap:8}}>
          <input className="input" placeholder="Широта" value={form.lat} onChange={e=>set('lat', e.target.value)} required />
          <input className="input" placeholder="Долгота" value={form.lng} onChange={e=>set('lng', e.target.value)} required />
        </div>
        <input className="input" placeholder="URL фото через запятую" value={form.photos} onChange={e=>set('photos', e.target.value)} />
        <button className="btn primary" type="submit">Сохранить</button>
        {msg && <div className="muted">{msg}</div>}
      </form>
    </div>
  );
};
export default AddPlacePage;
