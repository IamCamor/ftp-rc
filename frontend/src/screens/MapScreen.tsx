import React,{useEffect,useMemo,useRef} from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import {api} from "../lib/api";

export default function MapScreen(){
  const ref=useRef<HTMLDivElement>(null);
  const species=useMemo(()=> new URLSearchParams(location.hash.split('?')[1]||'').get('species') || '', []);
  useEffect(()=>{ if(!ref.current) return;
    const center:[number,number]=[55.7558,37.6173];
    const map=L.map(ref.current,{zoomControl:true,attributionControl:false}).setView(center,11);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(map);
    const group=L.layerGroup().addTo(map);

    async function load(){
      group.clearLayers();
      if(species){
        const j:any=await api.catchMarkers({species});
        (j.items||[]).forEach((m:any)=>{
          L.marker([m.lat,m.lng]).addTo(group).bindPopup(`<b>${m.species||''}</b> <br/><a href="#/catch/${m.id}">Открыть улов</a>`);
        });
      }else{
        const bounds=map.getBounds(); const bbox=[bounds.getWest(),bounds.getSouth(),bounds.getEast(),bounds.getNorth()].join(',');
        const j:any=await api.points({limit:500,bbox});
        (j.items||[]).forEach((p:any)=>{
          L.marker([p.lat,p.lng]).addTo(group).bindPopup(`<b>${p.title||''}</b>`);
        });
      }
    }
    load(); map.on('moveend',()=>{ if(!species) load(); });

    return ()=>{ map.remove(); };
  },[species]);

  return <div className="w-full h-[calc(100vh-84px)]">{/* 84px под нижнюю навигацию */}
    <div ref={ref} className="w-full h-full" />
  </div>;
}
