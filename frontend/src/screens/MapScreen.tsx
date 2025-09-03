import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";
import api from "../data/api";

// Предполагается, что leaflet уже подключён в проекте
// Если используете react-leaflet — адаптируйте импорты.
declare const L:any;

type Point = {
  id:number; title:string; lat:number; lng:number;
  category?:string; photo_url?:string; media_url?:string;
  type?:string;
};

export default function MapScreen(){
  const [points,setPoints]=useState<Point[]>([]);
  const [map,setMap]=useState<any>(null);

  useEffect(()=> {
    if (typeof window !== "undefined" && (window as any).L && !map) {
      const m = L.map('map', { zoomControl: true }).setView([55.75, 37.61], 10);
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap'
      }).addTo(m);
      setMap(m);
    }
  },[map]);

  useEffect(()=> {
    (async ()=>{
      try{
        const j:any = await api.points(`?limit=500`);
        const items:Point[] = j?.items || [];
        setPoints(items);
      }catch(e){}
    })();
  },[]);

  useEffect(()=> {
    if(!map) return;
    const layer = L.layerGroup().addTo(map);
    points.forEach(p=>{
      const marker = L.marker([p.lat, p.lng]).addTo(layer);
      const img = p.photo_url || p.media_url;
      const content = `
        <div style="min-width:200px">
          <div style="font-weight:600;margin-bottom:6px">${p.title||"Точка"}</div>
          ${img ? `<img src="${img}" style="width:100%;border-radius:10px;cursor:pointer" id="pin-img-${p.id}"/>` : ""}
          <div style="margin-top:6px">
            <a href="/place/${p.id}" style="color:#2563eb;text-decoration:none">Открыть место</a>
          </div>
        </div>`;
      marker.bindPopup(content);

      marker.on('popupopen', ()=>{
        const el = document.getElementById(`pin-img-${p.id}`);
        if(el){
          el.addEventListener('click', ()=> {
            window.location.href = `/place/${p.id}`;
          }, { once:true });
        }
      });
    });
    return ()=> { map.removeLayer(layer); };
  },[map, points]);

  return (
    <div className="w-full h-full relative">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="font-semibold inline-flex items-center gap-2"><Icon name="map"/> Карта</div>
        <a href="/weather" className="text-sm inline-flex items-center gap-1"><Icon name="weather"/> Погода</a>
      </div>
      <div id="map" className="absolute inset-0 z-map" />
    </div>
  );
}
