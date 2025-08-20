import React, { useEffect, useMemo, useRef, useState } from "react";
import { MapContainer, TileLayer, CircleMarker, Popup, useMapEvents } from "react-leaflet";
import type { LatLngBounds, LatLngExpression } from "leaflet";
import { getPoints } from "../data/api";
import type { Point } from "../data/types";
import { useDebounce } from "../utils/useDebounce";

export default function MapView({ filter, q }:{filter:"Все"|"Споты"|"Магазины"|"Слипы"|"Кемпинги"|"Уловы"; q:string}) {
  const [points,setPoints]=useState<Point[]>([]); const [error,setError]=useState<string|null>(null);
  const [bounds,setBounds]=useState<LatLngBounds|null>(null); const debouncedQ=useDebounce(q,300); const loading=useRef(false);
  const center:LatLngExpression=[55.7558,37.6173];
  const mapFilter:Record<string,string|undefined>={ "Все":undefined,"Споты":"spot","Магазины":"shop","Слипы":"slip","Кемпинги":"camp","Уловы":"catch" };

  function BoundsWatcher({on}:{on:(b:LatLngBounds)=>void}){ useMapEvents({moveend:(e)=>on(e.target.getBounds()), zoomend:(e)=>on(e.target.getBounds())}); return null; }

  useEffect(()=>{ let cancel=false;
    (async()=>{
      if(loading.current) return; loading.current=true; setError(null);
      try{
        const t=mapFilter[filter]; const bbox=bounds?[bounds.getWest(),bounds.getSouth(),bounds.getEast(),bounds.getNorth()] as [number,number,number,number]:undefined;
        const items=await getPoints({filter:t,bbox,limit:500,q:debouncedQ}); if(!cancel) setPoints(items);
      }catch(e:any){ if(!cancel) setError(e?.message??"Ошибка загрузки"); } finally{ loading.current=false; }
    })(); return ()=>{cancel=true};
  },[filter,bounds,debouncedQ]);

  const shown=useMemo(()=>{ const text=debouncedQ.trim().toLowerCase(); if(!text) return points;
    return points.filter(p=>[p.title,p.description??"",p.address??"",...(p.tags??[])].join(" ").toLowerCase().includes(text));
  },[points,debouncedQ]);

  return (
    <div className="w-full h-full">
      <MapContainer center={center} zoom={12} className="w-full h-full">
        <TileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png" attribution='&copy; <a href="https://carto.com/">CARTO</a>'/>
        <BoundsWatcher on={setBounds}/>
        {shown.map(p=>(
          <CircleMarker key={p.id} center={[p.lat,p.lng]} radius={8} pathOptions={{color:"#FF7CA3",weight:2,fillColor:"#FFB88C",fillOpacity:0.9}}>
            <Popup>
              <div className="text-sm max-w-[220px]">
                <div className="font-medium">{p.title}</div>
                {p.type && <div className="text-gray-500 mt-1">Тип: {p.type}</div>}
                {p.description && <div className="mt-1">{p.description}</div>}
                {p.address && <div className="mt-1 text-gray-600">{p.address}</div>}
                {p.tags?.length ? <div className="mt-1 text-xs text-gray-500">#{p.tags.join(" #")}</div> : null}
              </div>
            </Popup>
          </CircleMarker>
        ))}
      </MapContainer>
      {error && <div className="fixed top-24 left-1/2 -translate-x-1/2 px-3 py-1 text-xs rounded-md text-white bg-red-500/80 z-[1400]">{error}</div>}
    </div>
  );
}
