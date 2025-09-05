import React from "react";
import Icon from "../components/Icon";
import { API } from "../api";

export default function AddPlacePage(){
  const [form,setForm]=React.useState<any>({ name:"", type:"spot", lat:"", lng:"", description:"" });
  const [loading,setLoading]=React.useState(false);

  const onChange=(e:React.ChangeEvent<HTMLInputElement|HTMLTextAreaElement|HTMLSelectElement>)=>{
    const {name,value}=e.target;
    setForm((s:any)=>({...s,[name]:value}));
  };

  const submit=async(e:React.FormEvent)=>{
    e.preventDefault();
    try{
      setLoading(true);
      const payload = {
        ...form,
        lat: Number(form.lat),
        lng: Number(form.lng),
      };
      const res = await API.addPlace(payload);
      console.log(res);
      alert("Место сохранено");
    }catch(err:any){
      alert("Ошибка сохранения: "+(err?.message||err));
    }finally{ setLoading(false); }
  };

  return (
    <div className="page addplace-page">
      <div className="page-title">
        <Icon name="addLocation" size={22}/> <h1>Добавить место</h1>
      </div>
      <form className="form" onSubmit={submit}>
        <div className="grid">
          <label>Название
            <input name="name" value={form.name} onChange={onChange} placeholder="Название точки"/>
          </label>
          <label>Тип
            <select name="type" value={form.type} onChange={onChange}>
              <option value="spot">Место</option>
              <option value="base">База</option>
              <option value="shop">Магазин</option>
            </select>
          </label>
          <label>Широта (lat)
            <input name="lat" value={form.lat} onChange={onChange} placeholder="55.75"/>
          </label>
          <label>Долгота (lng)
            <input name="lng" value={form.lng} onChange={onChange} placeholder="37.62"/>
          </label>
          <label className="full">Описание
            <textarea name="description" value={form.description} onChange={onChange} placeholder="Кратко опишите место"/>
          </label>
        </div>
        <div className="form-actions">
          <button className="btn primary" disabled={loading}><Icon name="save"/> {loading?"Сохранение…":"Сохранить место"}</button>
        </div>
      </form>
    </div>
  );
}
