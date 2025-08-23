import React, { useState } from "react";
import { buildUrl } from "../lib/api";
import { toast } from "../lib/toast";

export default function AddCatchScreen({onDone}:{onDone:()=>void}) {
  const [form, setForm] = useState({
    species: "", length: "", weight: "", style: "", lure: "", tackle: "",
    notes: "", photo_url: "", lat: "", lng: "", caught_at: "", privacy: "all"
  });
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string|null>(null);

  const set = (k: string, v: string) => setForm(p=>({...p, [k]: v}));

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true); setErr(null);
    try {
      const payload: any = {
        lat: Number(form.lat), lng: Number(form.lng),
        species: form.species || null,
        length: form.length ? Number(form.length) : null,
        weight: form.weight ? Number(form.weight) : null,
        style: form.style || null, lure: form.lure || null, tackle: form.tackle || null,
        notes: form.notes || null, photo_url: form.photo_url || null,
        caught_at: form.caught_at || null,
        privacy: form.privacy || "all",
      };
      const res = await fetch(buildUrl("/api/v1/catches"), {
        method: "POST",
        headers: { "Content-Type":"application/json", "Accept":"application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      toast("Улов добавлен");
      onDone();
    } catch (e:any) {
      setErr(e.message ?? String(e));
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submit} className="space-y-3">
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Широта (lat)" value={form.lat} onChange={e=>set("lat", e.target.value)} required />
        <input className="input" placeholder="Долгота (lng)" value={form.lng} onChange={e=>set("lng", e.target.value)} required />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Вид рыбы" value={form.species} onChange={e=>set("species", e.target.value)} />
        <input className="input" placeholder="Вес (кг)" value={form.weight} onChange={e=>set("weight", e.target.value)} />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Длина (см)" value={form.length} onChange={e=>set("length", e.target.value)} />
        <input className="input" placeholder="Стиль" value={form.style} onChange={e=>set("style", e.target.value)} />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Приманка" value={form.lure} onChange={e=>set("lure", e.target.value)} />
        <input className="input" placeholder="Снасти" value={form.tackle} onChange={e=>set("tackle", e.target.value)} />
      </div>
      <input className="input" placeholder="Фото (URL)" value={form.photo_url} onChange={e=>set("photo_url", e.target.value)} />
      <input className="input" type="datetime-local" placeholder="Дата/время" value={form.caught_at} onChange={e=>set("caught_at", e.target.value)} />
      <select className="input" value={form.privacy} onChange={e=>set("privacy", e.target.value)}>
        <option value="all">Публично</option>
        <option value="friends">Друзья</option>
        <option value="private">Приватно</option>
      </select>
      <textarea className="input" placeholder="Заметки" value={form.notes} onChange={e=>set("notes", e.target.value)} />
      {err && <div className="text-red-500 text-sm">{err}</div>}
      <div className="flex gap-2 justify-end">
        <button type="button" className="btn-secondary" onClick={onDone}>Отмена</button>
        <button type="submit" className="btn-primary" disabled={loading}>{loading?"Сохранение…":"Сохранить"}</button>
      </div>
    </form>
  );
}
