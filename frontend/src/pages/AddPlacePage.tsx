import React, { useState } from 'react';
import { createPlace } from '../api';
import { useNavigate } from 'react-router-dom';

const AddPlacePage:React.FC = () => {
  const nav = useNavigate();
  const qs = new URLSearchParams(location.search);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [lat, setLat] = useState<number>(Number(qs.get('lat')) || 55.75);
  const [lng, setLng] = useState<number>(Number(qs.get('lng')) || 37.61);
  const [waterType, setWaterType] = useState<'river'|'lake'|'sea'|'pond'|'other'>('river');
  const [access, setAccess] = useState<'free'|'paid'|'restricted'>('free');
  const [season, setSeason] = useState('');
  const [tags, setTags] = useState('');
  const [photos, setPhotos] = useState<File[]>([]);
  const [privacy, setPrivacy] = useState<'all'|'friends'|'private'>('all');
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState('');

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) { setMsg('Название обязательно'); return; }
    setBusy(true); setMsg('');
    try {
      const res = await createPlace({
        title, description, lat, lng,
        water_type: waterType, access, season, tags,
        photos, privacy
      });
      setMsg('✅ Место добавлено');
      const id = res?.id;
      setTimeout(()=> nav(id ? `/place/${id}` : '/map'), 600);
    } catch (e:any) {
      setMsg(`Ошибка: ${e?.message || 'не удалось отправить'}`);
    } finally { setBusy(false); }
  }

  return (
    <div className="container">
      <form className="glass card" style={{marginTop:16}} onSubmit={submit}>
        <h2>Добавить место</h2>
        {msg && <div className="subtle" style={{marginBottom:8}}>{msg}</div>}
        <div style={{display:'grid', gap:10}}>
          <label>Название* <input value={title} onChange={e=>setTitle(e.target.value)} required/></label>
          <label>Описание <textarea rows={3} value={description} onChange={e=>setDescription(e.target.value)} /></label>

          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Широта <input type="number" step="0.00001" value={lat} onChange={e=>setLat(Number(e.target.value))} /></label>
            <label>Долгота <input type="number" step="0.00001" value={lng} onChange={e=>setLng(Number(e.target.value))} /></label>
          </div>

          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Водоём
              <select value={waterType} onChange={e=>setWaterType(e.target.value as any)}>
                <option value="river">Река</option>
                <option value="lake">Озеро</option>
                <option value="sea">Море</option>
                <option value="pond">Пруд</option>
                <option value="other">Другое</option>
              </select>
            </label>
            <label>Доступ
              <select value={access} onChange={e=>setAccess(e.target.value as any)}>
                <option value="free">Свободный</option>
                <option value="paid">Платный</option>
                <option value="restricted">Ограниченный</option>
              </select>
            </label>
          </div>

          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Сезон/период <input value={season} onChange={e=>setSeason(e.target.value)} placeholder="весна, лето…"/></label>
            <label>Теги <input value={tags} onChange={e=>setTags(e.target.value)} placeholder="окунь, лодка…"/></label>
          </div>

          <label>Фото
            <input multiple type="file" accept="image/*" onChange={e=>setPhotos(Array.from(e.target.files || []))} />
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
export default AddPlacePage;
