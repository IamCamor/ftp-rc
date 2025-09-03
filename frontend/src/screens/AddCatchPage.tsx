// src/screens/AddCatchPage.tsx
import React, { useEffect, useState } from "react";
import HeaderBar from "../components/HeaderBar";
import { api } from "../api";

export default function AddCatchPage() {
  const [form, setForm] = useState<any>({ species: "", caption: "", lat: 55.7558, lng: 37.6173, caught_at: new Date().toISOString().slice(0,16) });
  const [files, setFiles] = useState<File[]>([]);
  const [loading, setLoading] = useState(false);
  const [wx, setWx] = useState<any>({});

  useEffect(() => {
    api.weather(form.lat, form.lng, Math.floor(new Date(form.caught_at).getTime()/1000)).then(setWx).catch(()=>{});
  }, [form.lat, form.lng, form.caught_at]);

  const set = (k: string, v: any) => setForm((x: any)=>({ ...x, [k]: v }));

  const submit = async () => {
    setLoading(true);
    try {
      let media_url = "";
      if (files.length) {
        const up = await api.upload(files);
        media_url = up.items?.[0]?.url || "";
      }
      const payload = {
        species: form.species,
        caption: form.caption,
        lat: Number(form.lat), lng: Number(form.lng),
        caught_at: new Date(form.caught_at).toISOString(),
        weather: wx?.current || null,
        media_url,
        privacy: "public",
      };
      const res = await api.addCatch(payload);
      window.location.hash = `#/catch/${res?.id || ""}`;
    } catch (e:any) {
      alert("Ошибка сохранения: " + (e?.message || e));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="w-full h-full">
      <HeaderBar title="Добавить улов" />
      <div className="mx-auto max-w-md px-3 mt-16 pb-28">
        <div className="glass p-4 space-y-3">
          <div>
            <label className="text-sm text-gray-600">Вид рыбы</label>
            <input className="w-full mt-1 glass px-3 py-2" value={form.species} onChange={e=>set("species", e.target.value)} placeholder="Окунь" />
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
          <div>
            <label className="text-sm text-gray-600">Дата и время</label>
            <input type="datetime-local" className="w-full mt-1 glass px-3 py-2" value={form.caught_at} onChange={e=>set("caught_at", e.target.value)} />
          </div>
          <div>
            <label className="text-sm text-gray-600">Описание</label>
            <textarea className="w-full mt-1 glass px-3 py-2" rows={3} value={form.caption} onChange={e=>set("caption", e.target.value)} placeholder="Как и где поймал" />
          </div>
          <div>
            <label className="text-sm text-gray-600">Фото/видео</label>
            <input type="file" multiple accept="image/*,video/*" onChange={(e)=>setFiles(Array.from(e.target.files||[]))} className="mt-1" />
          </div>
          <div className="text-sm text-gray-600">
            Погода: <b>{wx?.current?.temp ?? "—"}</b>, ветер <b>{wx?.current?.wind_speed ?? "—"}</b>
          </div>
          <button onClick={submit} disabled={loading} className="w-full py-3 rounded-xl bg-gradient-to-r from-pink-400 to-purple-500 text-white">
            {loading ? "Сохранение…" : "Сохранить улов"}
          </button>
        </div>
      </div>
    </div>
  );
}
