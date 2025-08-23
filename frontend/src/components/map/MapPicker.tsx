import React, {useEffect,useRef} from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
type Props={lat?:number;lng?:number;onPick:(lat:number,lng:number)=>void;height?:number|string};
export default function MapPicker({lat=55.7558,lng=37.6173,onPick,height=400}:Props){
  const ref=useRef<HTMLDivElement>(null); const markerRef=useRef<L.Marker|null>(null);
  useEffect(()=>{ if(!ref.current) return;
    const map=L.map(ref.current,{zoomControl:true,attributionControl:false}).setView([lat,lng],11);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(map);
    markerRef.current=L.marker([lat,lng],{draggable:true}).addTo(map);
    const ondrag=()=>{const p=markerRef.current!.getLatLng(); onPick(p.lat,p.lng);};
    markerRef.current.on('dragend',ondrag);
    map.on('click',(e:any)=>{const {lat,lng}=e.latlng; markerRef.current!.setLatLng([lat,lng]); onPick(lat,lng);});
    return ()=>{ map.remove(); };
  },[]);
  return <div ref={ref} style={{height}} className="rounded-2xl overflow-hidden border border-white/60" />;
}
