import React from "react";
import Icon from "../components/Icon";
import { API } from "../api";

type SavedLoc = { id:string; name:string; lat:number; lng:number };
type W = { temp?:number; wind?:number; pressure?:number; source?:string; };

const storeKey = "weather.locations";

export default function WeatherPage(){
  const [list,setList]=React.useState<SavedLoc[]>(()=> {
    try{ return JSON.parse(localStorage.getItem(storeKey)||"[]"); }catch{ return []; }
  });
  const [wx, setWx] = React.useState<Record<string,W>>({});

  const add = async ()=>{
    const name = prompt("Название локации (например, Дом)");
    const lat = Number(prompt("Широта (lat), напр. 55.75"));
    const lng = Number(prompt("Долгота (lng), напр. 37.62"));
    if(!name || Number.isNaN(lat) || Number.isNaN(lng)) return;
    const item = { id: Date.now().toString(), name, lat, lng };
    const next = [...list, item];
    setList(next);
    localStorage.setItem(storeKey, JSON.stringify(next));
    loadOne(item);
  };

  const del = (id:string)=>{
    const next = list.filter(i=>i.id!==id);
    setList(next);
    localStorage.setItem(storeKey, JSON.stringify(next));
  };

  const loadOne = async (loc:SavedLoc)=>{
    try{
      const data:any = await API.weather(loc.lat, loc.lng);
      setWx(s=>({...s,[loc.id]:{
        temp: data?.temp ?? data?.main?.temp,
        wind: data?.wind_speed ?? data?.wind?.speed,
        pressure: data?.pressure ?? data?.main?.pressure,
        source: data?.source || "openweather"
      }}));
    }catch(e){
      console.warn("weather failed", e);
      setWx(s=>({...s,[loc.id]:{}}));
    }
  };

  React.useEffect(()=>{
    list.forEach(loadOne);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  },[]);

  return (
    <div className="page weather-page">
      <div className="page-title">
        <Icon name="weather" size={24}/> <h1>Погода</h1>
        <button className="btn" onClick={add}><Icon name="add" /> Добавить локацию</button>
      </div>
      {!list.length && <div className="empty">Добавьте свою первую локацию →</div>}
      <div className="cards">
        {list.map(loc=>{
          const w = wx[loc.id]||{};
          return (
            <div key={loc.id} className="card">
              <div className="card-h">
                <div>
                  <b>{loc.name}</b>
                  <div className="muted">{loc.lat.toFixed(3)}, {loc.lng.toFixed(3)}</div>
                </div>
                <button className="icon-btn" onClick={()=>del(loc.id)} title="Удалить"><Icon name="delete"/></button>
              </div>
              <div className="wx">
                <div><span className="lbl">Темп.</span><b>{w.temp ?? "—"}</b></div>
                <div><span className="lbl">Ветер</span><b>{w.wind ?? "—"}</b></div>
                <div><span className="lbl">Давл.</span><b>{w.pressure ?? "—"}</b></div>
                <div className="muted small">src: {w.source||"—"}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
