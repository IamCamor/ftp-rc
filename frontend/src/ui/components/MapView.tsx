import { useEffect, useMemo, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { fetchMapPoints, MapPoint } from "../data/api";

const icon = L.icon({
  iconUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize:[25,41], iconAnchor:[12,41]
});

const DEMO:MapPoint[] = [
  { id:1, lat:55.751244, lng:37.618423, title:"Спот: Москва-река", type:"spot", is_highlighted:true },
  { id:2, lat:59.93863, lng:30.31413, title:"Магазин снастей", type:"shop" },
  { id:3, lat:60.003, lng:30.2, title:"Слип", type:"slip" }
];

export default function MapView(){
  const [points,setPoints] = useState<MapPoint[]>(DEMO);
  useEffect(()=>{ let m=true;
    fetchMapPoints({}).then(it=>{ if(m && Array.isArray(it) && it.length) setPoints(it); })
    .catch(()=>{}); return ()=>{ m=false; }; },[]);
  const center = useMemo(()=>[55.76,37.64] as [number,number],[]);
  return (
    <div style={{height:"calc(100vh - 140px)"}}>
      <MapContainer center={center} zoom={6} scrollWheelZoom className="glass">
        <TileLayer attribution='&copy; OSM' url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"/>
        {points.map(p=>(
          <Marker key={p.id} position={[p.lat,p.lng]} icon={icon}>
            <Popup><b>{p.title}</b><br/>Тип: {p.type}{p.is_highlighted?" ⭐":""}</Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}
