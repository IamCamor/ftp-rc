
import React from "react";
import { api } from "../data/api.extras";

type SavedLoc = { id:number; title:string; lat:number; lng:number };

export default function WeatherScreen(){
  const [items,setItems]=React.useState<SavedLoc[]>([]);
  const [title,setTitle]=React.useState(""); const [lat,setLat]=React.useState<string>(""); const [lng,setLng]=React.useState<string>("");
  const [wx,setWx]=React.useState<Record<number, any>>({});

  const load = async ()=>{
    const res = await api.getJSON("/weather-locations");
    const arr:SavedLoc[] = res?.items ?? res ?? [];
    setItems(arr);
    // загрузим погоду (fail-open: если 204 — пропустим)
    const out:Record<number,any> = {};
    for(const it of arr){
      try{
        const w = await api.getJSON(`/weather?lat=${it.lat}&lng=${it.lng}`);
        if (w) out[it.id]=w;
      }catch(e){}
    }
    setWx(out);
  };

  React.useEffect(()=>{ load(); },[]);

  const add = async ()=>{
    if(!title || !lat || !lng) return;
    await api.postJSON("/weather-locations", { title, lat:parseFloat(lat), lng:parseFloat(lng) });
    setTitle(""); setLat(""); setLng("");
    await load();
  };
  const remove = async (id:number)=>{
    await api.delete(`/weather-locations/${id}`);
    await load();
  };

  return (
    <div className="w-full h-full p-4">
      <div className="max-w-md mx-auto space-y-4">
        <div className="backdrop-blur-md bg-white/60 border border-white/40 rounded-2xl p-4 shadow">
          <div className="text-sm text-gray-600 mb-2">Избранные локации</div>
          <div className="space-y-3">
            {items.map(it=>(
              <div key={it.id} className="flex items-center justify-between">
                <div>
                  <div className="font-medium">{it.title}</div>
                  <div className="text-xs text-gray-500">{it.lat}, {it.lng}</div>
                </div>
                <div className="text-sm">
                  {wx[it.id]?.main ? `${Math.round(wx[it.id].main.temp)}°` : <span className="text-gray-400">—</span>}
                </div>
                <button onClick={()=>remove(it.id)} className="text-gray-400 hover:text-red-500">Удалить</button>
              </div>
            ))}
            {items.length===0 && <div className="text-gray-500 text-sm">Сохранённых локаций пока нет</div>}
          </div>
        </div>

        <div className="backdrop-blur-md bg-white/60 border border-white/40 rounded-2xl p-4 shadow space-y-2">
          <div className="text-sm text-gray-600">Добавить локацию</div>
          <input value={title} onChange={e=>setTitle(e.target.value)} placeholder="Название" className="w-full rounded-xl border px-3 py-2 bg-white/80"/>
          <div className="flex gap-2">
            <input value={lat} onChange={e=>setLat(e.target.value)} placeholder="Широта" className="flex-1 rounded-xl border px-3 py-2 bg-white/80"/>
            <input value={lng} onChange={e=>setLng(e.target.value)} placeholder="Долгота" className="flex-1 rounded-xl border px-3 py-2 bg-white/80"/>
          </div>
          <button onClick={add} className="w-full rounded-xl bg-pink-600 text-white py-2">Сохранить</button>
        </div>
      </div>
    </div>
  );
}
