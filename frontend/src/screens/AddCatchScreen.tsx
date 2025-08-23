import React, { useEffect, useMemo, useState } from "react";
import { Card, CardContent, Button, Input, Textarea, Select } from "../components/ui";
import Uploader from "../components/Uploader";
import MapPicker from "../components/map/MapPicker";
import { apiGet, apiPostJSON } from "../lib/api";
import { toast } from "../lib/toast";

export default function AddCatchScreen({onDone}:{onDone:()=>void}) {
  const [form, setForm] = useState({
    lat: 55.7558, lng: 37.6173,
    species: "", length: "", weight: "",
    style: "", lure: "", tackle: "",
    notes: "", photo_url: "", caught_at: "", privacy: "all",
    water_type:"", water_temp:"", wind_speed:"", pressure:""
  });
  const [loading, setLoading] = useState(false);

  const set = (k:string,v:any)=> setForm(p=>({...p,[k]:v}));

  const ts = useMemo(()=> {
    if (!form.caught_at) return null;
    const t = new Date(form.caught_at);
    return Math.floor(t.getTime()/1000);
  }, [form.caught_at]);

  useEffect(()=>{
    // авто-погода при наличии координат и времени
    if (!form.lat || !form.lng) return;
    const run = async ()=>{
      try{
        const j:any = await apiGet('/api/v1/weather', { lat: form.lat, lng: form.lng, dt: ts || undefined });
        const d = j.data;
        // извлечём "самое похоже" — current (или первый из data)
        const current = d?.current ?? d?.data?.[0] ?? null;
        if (current) {
          if (current.temp != null) set('water_temp', current.temp); // формально это air temp, но для UX — ок до добавления реальных сенсоров
          if (current.wind_speed != null) set('wind_speed', current.wind_speed);
          if (current.pressure != null) set('pressure', current.pressure);
        }
      }catch(e){ /* молча */ }
    };
    run();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [form.lat, form.lng, ts]);

  const submit = async (e: React.FormEvent)=>{
    e.preventDefault();
    setLoading(true);
    try{
      const payload:any = {
        lat: Number(form.lat), lng: Number(form.lng),
        species: form.species || null,
        length: form.length ? Number(form.length) : null,
        weight: form.weight ? Number(form.weight) : null,
        style: form.style || null, lure: form.lure || null, tackle: form.tackle || null,
        notes: form.notes || null, photo_url: form.photo_url || null,
        caught_at: form.caught_at || null, privacy: form.privacy || "all",
        water_type: form.water_type || null,
        water_temp: form.water_temp ? Number(form.water_temp) : null,
        wind_speed: form.wind_speed ? Number(form.wind_speed) : null,
        pressure: form.pressure ? Number(form.pressure) : null
      };
      await apiPostJSON('/api/v1/catches', payload);
      toast("Улов добавлен");
      onDone();
    }catch(e:any){
      toast("Ошибка сохранения");
      console.error(e);
    }finally{
      setLoading(false);
    }
  };

  return (
    <Card>
      <CardContent>
        <form onSubmit={submit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <Input placeholder="Вид рыбы" value={form.species} onChange={e=>set('species', e.target.value)} />
            <Input placeholder="Дата/время" type="datetime-local" value={form.caught_at} onChange={e=>set('caught_at', e.target.value)} />
            <Input placeholder="Вес (кг)" value={form.weight} onChange={e=>set('weight', e.target.value)} />
            <Input placeholder="Длина (см)" value={form.length} onChange={e=>set('length', e.target.value)} />
            <Input placeholder="Стиль" value={form.style} onChange={e=>set('style', e.target.value)} />
            <Input placeholder="Приманка" value={form.lure} onChange={e=>set('lure', e.target.value)} />
            <Input placeholder="Снасти" value={form.tackle} onChange={e=>set('tackle', e.target.value)} />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Input placeholder="Широта (lat)" value={form.lat} onChange={e=>set('lat', Number(e.target.value))} />
            <Input placeholder="Долгота (lng)" value={form.lng} onChange={e=>set('lng', Number(e.target.value))} />
          </div>

          <MapPicker lat={form.lat} lng={form.lng} onPick={(a,b)=>{ set('lat',a); set('lng',b); }} height={250} />

          <Uploader onUploaded={(url)=> set('photo_url', url)} />
          {form.photo_url && <div className="text-xs text-gray-600 break-all">Файл: {form.photo_url}</div>}

          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <Select value={form.privacy} onChange={e=>set('privacy', e.target.value)}>
              <option value="all">Публично</option>
              <option value="friends">Друзья</option>
              <option value="private">Приватно</option>
            </Select>
            <Input placeholder="Тип воды" value={form.water_type} onChange={e=>set('water_type', e.target.value)} />
            <Input placeholder="Темп. воды/воздуха (°C)" value={form.water_temp} onChange={e=>set('water_temp', e.target.value)} />
            <Input placeholder="Ветер (м/с)" value={form.wind_speed} onChange={e=>set('wind_speed', e.target.value)} />
            <Input placeholder="Давление (гПа)" value={form.pressure} onChange={e=>set('pressure', e.target.value)} />
          </div>

          <Textarea placeholder="Заметки" value={form.notes} onChange={e=>set('notes', e.target.value)} />

          <div className="flex justify-end gap-2">
            <Button variant="secondary" onClick={onDone}>Отмена</Button>
            <Button type="submit">{loading ? "Сохранение…" : "Сохранить улов"}</Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
