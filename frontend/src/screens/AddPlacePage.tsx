import React, { useState } from "react";
import Icon from "../components/Icon";
import api from "../data/api";

export default function AddPlacePage(){
  const [lat,setLat]=useState<number>(55.75);
  const [lng,setLng]=useState<number>(37.61);
  const [title,setTitle]=useState("");
  const [category,setCategory]=useState("spot");
  const [files,setFiles]=useState<FileList|null>(null);
  const [mediaUrl,setMediaUrl]=useState("");

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
      const payload = {
        title, lat, lng, category,
        photo_url: uploaded || mediaUrl || null,
      };
      const saved:any = await api.addPlace(payload);
      window.location.href = `/place/${saved?.id || ''}`;
    }catch{
      alert("Ошибка сохранения места");
    }
  }

  return (
    <form onSubmit={onSubmit} className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="place"/><div className="font-semibold">Добавить место</div>
      </div>
      <div className="p-4 space-y-3">
        <div>
          <label className="block text-sm mb-1">Название</label>
          <input className="input" value={title} onChange={e=>setTitle(e.target.value)} />
        </div>
        <div className="grid grid-cols-2 gap-2">
          <div><label className="block text-sm mb-1">Широта</label><input className="input" value={lat} onChange={e=>setLat(parseFloat(e.target.value)||0)} /></div>
          <div><label className="block text-sm mb-1">Долгота</label><input className="input" value={lng} onChange={e=>setLng(parseFloat(e.target.value)||0)} /></div>
        </div>
        <div>
          <label className="block text-sm mb-1">Категория</label>
          <select className="input" value={category} onChange={e=>setCategory(e.target.value)}>
            <option value="spot">Спот</option>
            <option value="shop">Магазин</option>
            <option value="slip">Слип</option>
            <option value="camp">Кемпинг</option>
          </select>
        </div>
        <div>
          <label className="block text-sm mb-1">Фото/Видео</label>
          <input type="file" multiple accept="image/*,video/*" onChange={e=>setFiles(e.target.files)} />
          <div className="text-xs text-gray-500 mt-1">Или URL:</div>
          <input className="input" placeholder="https://..." value={mediaUrl} onChange={e=>setMediaUrl(e.target.value)} />
        </div>
        <button className="px-4 py-2 rounded-xl bg-black text-white">Сохранить</button>
      </div>
    </form>
  );
}
