import React,{useEffect,useMemo,useState} from "react";
import {Card,CardContent,Button,Input,Textarea,Select} from "../components/ui";
import MapPicker from "../components/map/MapPicker";
import {api, uploadFile} from "../lib/api";
import {toast} from "../lib/toast";

export default function AddCatchPage(){
  const [form,setForm]=useState({lat:55.7558,lng:37.6173,species:"",length:"",weight:"",style:"",lure:"",tackle:"",notes:"",photo_url:"",caught_at:"",privacy:"all",water_type:"",water_temp:"",wind_speed:"",pressure:""});
  const set=(k:string,v:any)=>setForm(p=>({...p,[k]:v}));
  const ts=useMemo(()=> form.caught_at? Math.floor(new Date(form.caught_at).getTime()/1000) : null,[form.caught_at]);
  useEffect(()=>{ if(!form.lat||!form.lng) return; (async()=>{
      try{ const j:any=await api.weather({lat:form.lat,lng:form.lng,dt:ts||undefined});
        const c = j?.data?.current ?? null;
        if(c){ if(c.temp!=null) set('water_temp',c.temp); if(c.wind_speed!=null) set('wind_speed',c.wind_speed); if(c.pressure!=null) set('pressure',c.pressure); }
      }catch{}
  })(); },[form.lat,form.lng,ts]);
  const onUpload=async(e:React.ChangeEvent<HTMLInputElement>)=>{
    const f=e.target.files?.[0]; if(!f) return;
    try{ const u=await uploadFile(f); set('photo_url',u.url); toast('Файл загружен'); }catch{ toast('Ошибка загрузки'); }
    e.target.value="";
  };
  const submit=async(e:React.FormEvent)=>{ e.preventDefault();
    try{
      await api.addCatch({
        lat:Number(form.lat),lng:Number(form.lng),species:form.species||null,length:form.length?Number(form.length):null,
        weight:form.weight?Number(form.weight):null,style:form.style||null,lure:form.lure||null,tackle:form.tackle||null,
        notes:form.notes||null,photo_url:form.photo_url||null,caught_at:form.caught_at||null,privacy:form.privacy||"all",
        water_type:form.water_type||null,water_temp:form.water_temp?Number(form.water_temp):null,wind_speed:form.wind_speed?Number(form.wind_speed):null,pressure:form.pressure?Number(form.pressure):null
      });
      toast('Улов добавлен'); location.hash="#/feed";
    }catch{ toast('Ошибка сохранения'); }
  };
  return <div className="p-4 pb-28 max-w-3xl mx-auto">
    <Card><CardContent>
      <form onSubmit={submit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <Input placeholder="Вид рыбы" value={form.species} onChange={e=>set('species',e.target.value)} />
          <Input placeholder="Дата/время" type="datetime-local" value={form.caught_at} onChange={e=>set('caught_at',e.target.value)} />
          <Input placeholder="Вес (кг)" value={form.weight} onChange={e=>set('weight',e.target.value)} />
          <Input placeholder="Длина (см)" value={form.length} onChange={e=>set('length',e.target.value)} />
          <Input placeholder="Стиль" value={form.style} onChange={e=>set('style',e.target.value)} />
          <Input placeholder="Приманка" value={form.lure} onChange={e=>set('lure',e.target.value)} />
          <Input placeholder="Снасти" value={form.tackle} onChange={e=>set('tackle',e.target.value)} />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Input placeholder="Широта (lat)" value={form.lat} onChange={e=>set('lat',Number(e.target.value))} />
          <Input placeholder="Долгота (lng)" value={form.lng} onChange={e=>set('lng',Number(e.target.value))} />
        </div>
        <MapPicker lat={form.lat} lng={form.lng} onPick={(a,b)=>{set('lat',a);set('lng',b);}} height={420}/>
        <div className="flex items-center gap-3">
          <label className="rounded-full px-4 py-2 bg-white/70 border border-white/60 cursor-pointer">
            Загрузить фото/видео <input type="file" className="hidden" accept="image/*,video/*" onChange={onUpload}/>
          </label>
          {form.photo_url && <span className="text-xs break-all">{form.photo_url}</span>}
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <Select value={form.privacy} onChange={e=>set('privacy',e.target.value)}>
            <option value="all">Публично</option><option value="friends">Друзья</option><option value="private">Приватно</option>
          </Select>
          <Input placeholder="Тип воды" value={form.water_type} onChange={e=>set('water_type',e.target.value)} />
          <Input placeholder="Температура (°C)" value={form.water_temp} onChange={e=>set('water_temp',e.target.value)} />
          <Input placeholder="Ветер (м/с)" value={form.wind_speed} onChange={e=>set('wind_speed',e.target.value)} />
          <Input placeholder="Давление (гПа)" value={form.pressure} onChange={e=>set('pressure',e.target.value)} />
        </div>
        <Textarea placeholder="Заметки" value={form.notes} onChange={e=>set('notes',e.target.value)} />
        <div className="flex justify-end gap-2">
          <Button variant="secondary" onClick={()=>history.back()}>Отмена</Button>
          <Button type="submit">Сохранить улов</Button>
        </div>
      </form>
    </CardContent></Card>
  </div>;
}
