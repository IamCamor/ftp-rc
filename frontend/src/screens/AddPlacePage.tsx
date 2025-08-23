import React,{useEffect,useState} from "react";
import {Card,CardContent,Button,Input,Textarea,Select} from "../components/ui";
import MapPicker from "../components/map/MapPicker";
import {api, uploadFile} from "../lib/api";
import {toast} from "../lib/toast";

export default function AddPlacePage(){
  const [cats,setCats]=useState<string[]>(["spot","shop","slip","camp"]);
  const [form,setForm]=useState({title:"",description:"",category:"spot",lat:55.7558,lng:37.6173,is_public:true,is_highlighted:false,preview_url:""});
  const set=(k:string,v:any)=>setForm(p=>({...p,[k]:v}));
  useEffect(()=>{ api.pointCats().then((j:any)=>Array.isArray(j.items)&&setCats(j.items)).catch(()=>{}); },[]);
  const onUpload=async(e:React.ChangeEvent<HTMLInputElement>)=>{
    const f=e.target.files?.[0]; if(!f) return;
    try{ const u=await uploadFile(f); set('preview_url',u.url); toast('Файл загружен'); }catch{ toast('Ошибка загрузки'); }
    e.target.value="";
  };
  const submit=async(e:React.FormEvent)=>{ e.preventDefault();
    try{
      await api.addPoint({title:form.title,description:form.description||null,category:form.category,lat:Number(form.lat),lng:Number(form.lng),
        is_public:!!form.is_public,is_highlighted:!!form.is_highlighted,status:'approved'});
      toast('Место добавлено'); location.hash="#/";
    }catch{ toast('Ошибка сохранения'); }
  };
  return <div className="p-4 pb-28 max-w-3xl mx-auto">
    <Card><CardContent>
      <form onSubmit={submit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <Input placeholder="Название" value={form.title} onChange={e=>set('title',e.target.value)} required />
          <Select value={form.category} onChange={e=>set('category',e.target.value)}>{cats.map(c=><option key={c} value={c}>{c}</option>)}</Select>
        </div>
        <Textarea placeholder="Описание" value={form.description} onChange={e=>set('description',e.target.value)} />
        <div className="grid grid-cols-2 gap-3">
          <Input placeholder="Широта (lat)" value={form.lat} onChange={e=>set('lat',Number(e.target.value))} />
          <Input placeholder="Долгота (lng)" value={form.lng} onChange={e=>set('lng',Number(e.target.value))} />
        </div>
        <MapPicker lat={form.lat} lng={form.lng} onPick={(a,b)=>{set('lat',a);set('lng',b);}} height={420}/>
        <div className="flex items-center gap-3">
          <label className="rounded-full px-4 py-2 bg-white/70 border border-white/60 cursor-pointer">
            Загрузить обложку <input type="file" className="hidden" accept="image/*" onChange={onUpload}/>
          </label>
          {form.preview_url && <span className="text-xs break-all">{form.preview_url}</span>}
        </div>
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={form.is_public} onChange={e=>set('is_public',e.target.checked)}/>Публично</label>
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={form.is_highlighted} onChange={e=>set('is_highlighted',e.target.checked)}/>Выделить</label>
        <div className="flex justify-end gap-2">
          <Button variant="secondary" onClick={()=>history.back()}>Отмена</Button>
          <Button type="submit">Сохранить место</Button>
        </div>
      </form>
    </CardContent></Card>
  </div>;
}
