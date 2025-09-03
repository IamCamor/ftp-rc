import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";
import api from "../data/api";

export default function AddCatchPage(){
  const [lat,setLat]=useState<number>(55.75);
  const [lng,setLng]=useState<number>(37.61);
  const [species,setSpecies]=useState("");
  const [length,setLength]=useState<number|''>('');
  const [weight,setWeight]=useState<number|''>('');
  const [style,setStyle]=useState("");
  const [lure,setLure]=useState("");
  const [tackle,setTackle]=useState("");
  const [privacy,setPrivacy]=useState<"all"|"friends"|"private">("all");
  const [caughtAt,setCaughtAt]=useState<string>(""); // yyyy-MM-ddTHH:mm
  const [files,setFiles]=useState<FileList|null>(null);
  const [mediaUrl,setMediaUrl]=useState<string>("");

  // погода подставляется, но не блокирует
  const [weather,setWeather]=useState<any>(null);
  useEffect(()=> {
    const dt = caughtAt ? Math.floor(new Date(caughtAt).getTime()/1000) : undefined;
    api.weather(lat,lng,dt).then(setWeather).catch(()=>{});
  },[lat,lng,caughtAt]);

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    try{
      let uploaded:string|undefined;
      if(files && files.length){
        const form = new FormData();
        Array.from(files).forEach(f=> form.append("files[]", f));
        const r:any = await api.upload(form);
        uploaded = r?.items?.[0]?.url || r?.url;
      }
      const payload:any = {
        lat, lng,
        species, length: length||null, weight: weight||null,
        style, lure, tackle, privacy,
        caught_at: caughtAt ? new Date(caughtAt).toISOString().slice(0,19).replace('T',' ') : null,
        photo_url: uploaded || mediaUrl || null,
        // погоду кладём как есть (бэкенд может игнорить)
        weather: weather || null,
      };
      const saved:any = await api.addCatch(payload);
      window.location.href = `/catch/${saved?.id || ''}`;
    }catch(err){
      alert("Ошибка сохранения улова");
    }
  }

  return (
    <form onSubmit={onSubmit} className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="photo"/><div className="font-semibold">Добавить улов</div>
      </div>
      <div className="p-4 space-y-3">
        <div>
          <label className="block text-sm mb-1">Координаты</label>
          <div className="flex gap-2">
            <input className="input" placeholder="Широта" value={lat} onChange={e=>setLat(parseFloat(e.target.value)||0)}/>
            <input className="input" placeholder="Долгота" value={lng} onChange={e=>setLng(parseFloat(e.target.value)||0)}/>
          </div>
          <div className="text-xs text-gray-500 mt-1">Можно выбрать точку на карте (будет добавлено в следующем коммите)</div>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <div><label className="block text-sm mb-1">Вид рыбы</label><input className="input" value={species} onChange={e=>setSpecies(e.target.value)} /></div>
          <div><label className="block text-sm mb-1">Стиль</label><input className="input" value={style} onChange={e=>setStyle(e.target.value)} /></div>
          <div><label className="block text-sm mb-1">Приманка</label><input className="input" value={lure} onChange={e=>setLure(e.target.value)} /></div>
          <div><label className="block text-sm mb-1">Снасть</label><input className="input" value={tackle} onChange={e=>setTackle(e.target.value)} /></div>
          <div><label className="block text-sm mb-1">Длина (см)</label><input className="input" type="number" value={length} onChange={e=>setLength(e.target.value===""? "" : Number(e.target.value))} /></div>
          <div><label className="block text-sm mb-1">Вес (г)</label><input className="input" type="number" value={weight} onChange={e=>setWeight(e.target.value===""? "" : Number(e.target.value))} /></div>
        </div>

        <div>
          <label className="block text-sm mb-1">Время поимки</label>
          <input className="input" type="datetime-local" value={caughtAt} onChange={e=>setCaughtAt(e.target.value)} />
        </div>

        <div>
          <label className="block text-sm mb-1">Фото/Видео</label>
          <input type="file" multiple accept="image/*,video/*" onChange={e=>setFiles(e.target.files)} />
          <div className="text-xs text-gray-500 mt-1">Или URL:</div>
          <input className="input" placeholder="https://..." value={mediaUrl} onChange={e=>setMediaUrl(e.target.value)} />
        </div>

        <div>
          <label className="block text-sm mb-1">Доступность</label>
          <select className="input" value={privacy} onChange={e=>setPrivacy(e.target.value as any)}>
            <option value="all">Публично</option>
            <option value="friends">Для друзей</option>
            <option value="private">Приватно</option>
          </select>
        </div>

        <button className="px-4 py-2 rounded-xl bg-black text-white">Сохранить</button>
      </div>
    </form>
  );
}
