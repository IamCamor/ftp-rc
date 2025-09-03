// src/screens/AddPlacePage.tsx
import React, { useState } from "react";
import HeaderBar from "../components/HeaderBar";
import { api } from "../api";

export default function AddPlacePage() {
  const [form, setForm] = useState<any>({ title: "", category: "spot", lat: 55.75, lng: 37.61 });
  const set = (k:string,v:any)=>setForm((x:any)=>({...x,[k]:v}));
  const submit = async ()=>{
    try{
      await api.addPlace({
        title: form.title,
        type: form.category,
        lat: Number(form.lat), lng: Number(form.lng),
      });
      alert("Место добавлено");
      window.location.hash="#/map";
    }catch(e:any){ alert("Ошибка: "+(e?.message||e)); }
  };
  return (
    <div className="w-full h-full">
      <HeaderBar title="Добавить место" />
      <div className="mx-auto max-w-md px-3 mt-16 pb-28">
        <div className="glass p-4 space-y-3">
          <div>
            <label className="text-sm text-gray-600">Название</label>
            <input className="w-full mt-1 glass px-3 py-2" value={form.title} onChange={e=>set("title", e.target.value)} />
          </div>
          <div>
            <label className="text-sm text-gray-600">Категория</label>
            <select className="w-full mt-1 glass px-3 py-2" value={form.category} onChange={e=>set("category", e.target.value)}>
              <option value="spot">Спот</option>
              <option value="shop">Магазин</option>
              <option value="slip">Слип</option>
              <option value="camp">Кемпинг</option>
              <option value="catch">Улов</option>
            </select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-sm text-gray-600">Широта</label>
              <input className="w-full mt-1 glass px-3 py-2" value={form.lat} onChange={e=>set("lat", e.target.value)} />
            </div>
            <div>
              <label className="text-sm text-gray-600">Долгота</label>
              <input className="w-full mt-1 glass px-3 py-2" value={form.lng} onChange={e=>set("lng", e.target.value)} />
            </div>
          </div>
          <button onClick={submit} className="w-full py-3 rounded-xl bg-gradient-to-r from-pink-400 to-purple-500 text-white">Сохранить</button>
        </div>
      </div>
    </div>
  );
}
