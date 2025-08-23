import React, { useEffect, useState } from "react";
import { buildUrl } from "../lib/api";
import { toast } from "../lib/toast";

export default function AddPlaceScreen({onDone}:{onDone:()=>void}) {
  const [cats, setCats] = useState<string[]>(["spot","shop","slip","camp"]);
  const [form, setForm] = useState({
    title:"", description:"", category:"spot", lat:"", lng:"",
    is_public:true, is_highlighted:false
  });
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string|null>(null);

  useEffect(() => {
    fetch(buildUrl("/api/v1/points/categories"))
      .then(r => r.ok ? r.json(): Promise.reject(r.status))
      .then(j => Array.isArray(j.items) ? setCats(j.items) : null)
      .catch(()=>{ /* необязательно */ });
  }, []);

  const set = (k: string, v: any) => setForm(p=>({...p, [k]: v}));

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true); setErr(null);
    try {
      const payload: any = {
        title: form.title,
        description: form.description || null,
        category: form.category,
        lat: Number(form.lat), lng: Number(form.lng),
        is_public: !!form.is_public,
        is_highlighted: !!form.is_highlighted,
        status: 'approved',
      };
      const res = await fetch(buildUrl("/api/v1/points"), {
        method: "POST",
        headers: { "Content-Type":"application/json", "Accept":"application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      toast("Место добавлено");
      onDone();
    } catch (e:any) {
      setErr(e.message ?? String(e));
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submit} className="space-y-3">
      <input className="input" placeholder="Название" value={form.title} onChange={e=>set("title", e.target.value)} required />
      <textarea className="input" placeholder="Описание" value={form.description} onChange={e=>set("description", e.target.value)} />
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Широта (lat)" value={form.lat} onChange={e=>set("lat", e.target.value)} required />
        <input className="input" placeholder="Долгота (lng)" value={form.lng} onChange={e=>set("lng", e.target.value)} required />
      </div>
      <select className="input" value={form.category} onChange={e=>set("category", e.target.value)}>
        {cats.map(c => <option key={c} value={c}>{c}</option>)}
      </select>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={form.is_public} onChange={e=>set("is_public", e.target.checked)} />
        Публично
      </label>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={form.is_highlighted} onChange={e=>set("is_highlighted", e.target.checked)} />
        Выделить на карте
      </label>
      {err && <div className="text-red-500 text-sm">{err}</div>}
      <div className="flex gap-2 justify-end">
        <button type="button" className="btn-secondary" onClick={onDone}>Отмена</button>
        <button type="submit" className="btn-primary" disabled={loading}>{loading?"Сохранение…":"Сохранить"}</button>
      </div>
    </form>
  );
}
