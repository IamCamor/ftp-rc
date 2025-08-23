import React, { useEffect, useState } from "react";
import { Card, CardContent, Button, Input, Textarea, Select } from "../components/ui";
import Uploader from "../components/Uploader";
import MapPicker from "../components/map/MapPicker";
import { apiGet, apiPostJSON } from "../lib/api";
import { toast } from "../lib/toast";

export default function AddPlaceScreen({onDone}:{onDone:()=>void}) {
  const [cats, setCats] = useState<string[]>(["spot","shop","slip","camp"]);
  const [form, setForm] = useState({
    title:"", description:"", category:"spot", lat:55.7558, lng:37.6173,
    is_public:true, is_highlighted:false, preview_url:""
  });
  const [loading, setLoading] = useState(false);
  const set = (k:string,v:any)=> setForm(p=>({...p,[k]:v}));

  useEffect(()=>{
    apiGet('/api/v1/points/categories').then((j:any)=>{
      if (Array.isArray(j.items)) setCats(j.items);
    }).catch(()=>{});
  },[]);

  const submit = async (e: React.FormEvent) =>{
    e.preventDefault(); setLoading(true);
    try{
      const payload:any = {
        title: form.title,
        description: form.description || null,
        category: form.category,
        lat: Number(form.lat), lng: Number(form.lng),
        is_public: !!form.is_public, is_highlighted: !!form.is_highlighted,
        status: 'approved'
      };
      await apiPostJSON('/api/v1/points', payload);
      toast("Место добавлено");
      onDone();
    }catch(e:any){
      toast("Ошибка сохранения");
      console.error(e);
    }finally{ setLoading(false); }
  };

  return (
    <Card>
      <CardContent>
        <form onSubmit={submit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <Input placeholder="Название" value={form.title} onChange={e=>set('title', e.target.value)} required />
            <Select value={form.category} onChange={e=>set('category', e.target.value)}>
              {cats.map(c => <option key={c} value={c}>{c}</option>)}
            </Select>
          </div>

          <Textarea placeholder="Описание" value={form.description} onChange={e=>set('description', e.target.value)} />

          <div className="grid grid-cols-2 gap-3">
            <Input placeholder="Широта (lat)" value={form.lat} onChange={e=>set('lat', Number(e.target.value))} />
            <Input placeholder="Долгота (lng)" value={form.lng} onChange={e=>set('lng', Number(e.target.value))} />
          </div>

          <MapPicker lat={form.lat} lng={form.lng} onPick={(a,b)=>{ set('lat',a); set('lng',b); }} height={250} />

          <Uploader onUploaded={(url)=> set('preview_url', url)} />
          {form.preview_url && <div className="text-xs text-gray-600 break-all">Обложка: {form.preview_url}</div>}

          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={form.is_public} onChange={e=>set('is_public', e.target.checked)} />
            Публично
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={form.is_highlighted} onChange={e=>set('is_highlighted', e.target.checked)} />
            Выделить на карте
          </label>

          <div className="flex justify-end gap-2">
            <Button variant="secondary" onClick={onDone}>Отмена</Button>
            <Button type="submit">{loading ? "Сохранение…" : "Сохранить место"}</Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
