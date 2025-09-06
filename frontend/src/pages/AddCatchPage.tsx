import React, { useState } from 'react';
import { createCatch, toMysqlDatetime } from '../api';
import { useNavigate } from 'react-router-dom';

const AddCatchPage:React.FC = () => {
  const nav = useNavigate();
  const qs = new URLSearchParams(location.search);
  const [lat, setLat] = useState<number>(Number(qs.get('lat')) || 55.75);
  const [lng, setLng] = useState<number>(Number(qs.get('lng')) || 37.61);
  const [species, setSpecies] = useState('');
  const [length, setLength] = useState<number|''>('');
  const [weight, setWeight] = useState<number|''>('');
  const [style, setStyle] = useState('');
  const [lure, setLure] = useState('');
  const [tackle, setTackle] = useState('');
  const [notes, setNotes] = useState('');
  const [photo, setPhoto] = useState<File|null>(null);
  const [caughtAt, setCaughtAt] = useState<string>(new Date().toISOString().slice(0,16)); // yyyy-MM-ddTHH:mm
  const [privacy, setPrivacy] = useState<'all'|'friends'|'private'>('all');
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string>('');

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!species.trim()) { setMsg('Укажите вид рыбы'); return; }
    setBusy(true); setMsg('');
    try {
      const payload = {
        lat, lng, species,
        length: length === '' ? undefined : Number(length),
        weight: weight === '' ? undefined : Number(weight),
        style, lure, tackle, notes,
        photo,
        caught_at: toMysqlDatetime(new Date(caughtAt)),
        privacy
      };
      const res = await createCatch(payload);
      setMsg('✅ Улов добавлен');
      const id = res?.id;
      setTimeout(()=> nav(id ? `/catch/${id}` : '/feed'), 600);
    } catch (e:any) {
      setMsg(`Ошибка: ${e?.message || 'не удалось отправить'}`);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="container">
      <form className="glass card" style={{marginTop:16}} onSubmit={submit}>
        <h2>Добавить улов</h2>
        {msg && <div className="subtle" style={{marginBottom:8}}>{msg}</div>}
        <div style={{display:'grid', gap:10}}>
          <label>Вид рыбы* <input value={species} onChange={e=>setSpecies(e.target.value)} required/></label>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Длина (см) <input type="number" step="0.1" value={length} onChange={e=>setLength(e.target.value===''?'':Number(e.target.value))} /></label>
            <label>Вес (кг) <input type="number" step="0.01" value={weight} onChange={e=>setWeight(e.target.value===''?'':Number(e.target.value))} /></label>
          </div>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Метод <input value={style} onChange={e=>setStyle(e.target.value)} /></label>
            <label>Приманка <input value={lure} onChange={e=>setLure(e.target.value)} /></label>
          </div>
          <label>Снасть <input value={tackle} onChange={e=>setTackle(e.target.value)} /></label>
          <label>Заметки <textarea value={notes} onChange={e=>setNotes(e.target.value)} rows={3} /></label>

          <label>Фото
            <input type="file" accept="image/*" onChange={e=>setPhoto(e.target.files?.[0] || null)} />
          </label>

          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Широта <input type="number" step="0.00001" value={lat} onChange={e=>setLat(Number(e.target.value))} /></label>
            <label>Долгота <input type="number" step="0.00001" value={lng} onChange={e=>setLng(Number(e.target.value))} /></label>
          </div>

          <label>Дата/время
            <input type="datetime-local" value={caughtAt} onChange={e=>setCaughtAt(e.target.value)} />
          </label>

          <label>Приватность
            <select value={privacy} onChange={e=>setPrivacy(e.target.value as any)}>
              <option value="all">Все</option>
              <option value="friends">Друзья</option>
              <option value="private">Только я</option>
            </select>
          </label>

          <div style={{display:'flex', gap:8}}>
            <button className="btn" disabled={busy} type="submit">
              <span className="material-symbols-rounded">save</span> Сохранить
            </button>
            <button className="btn" type="button" onClick={()=>history.back()}><span className="material-symbols-rounded">arrow_back</span>Назад</button>
          </div>
        </div>
      </form>
    </div>
  );
};
export default AddCatchPage;
