import { useCallback, useEffect, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { fetchMapPoints, MapPoint } from "../data/api";
import { Box, ToggleButton, ToggleButtonGroup } from "@mui/material";
const icon = L.icon({ iconUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png", iconSize:[25,41], iconAnchor:[12,41] });

function BboxFetcher({onBbox}:{onBbox:(bbox:string)=>void}){
  const map=useMapEvents({ moveend(){ const b=map.getBounds(); const bbox=[b.getWest(),b.getSouth(),b.getEast(),b.getNorth()].join(","); onBbox(bbox);} });
  useEffect(()=>{ const b=map.getBounds(); const bbox=[b.getWest(),b.getSouth(),b.getEast(),b.getNorth()].join(","); onBbox(bbox);},[]);
  return null;
}

export default function MapView(){
  const [points,setPoints]=useState<MapPoint[]>([]);
  const [bbox,setBbox]=useState<string>("");
  const [filter,setFilter]=useState<string>("");
  const busy=useRef(false);

  const load=useCallback(async ()=>{
    if (busy.current) return; busy.current=true;
    try{ const data=await fetchMapPoints({bbox, filter: filter || undefined}); setPoints(Array.isArray(data)?data:[]); }
    catch{ /* тихо */ }
    finally{ busy.current=false; }
  },[bbox,filter]);

  useEffect(()=>{ if(bbox) load(); },[bbox,filter,load]);

  return (
    <Box sx={{ position:"relative", height:"calc(100vh - 140px)" }}>
      <MapContainer center={[55.76,37.64]} zoom={6} scrollWheelZoom className="glass">
        <TileLayer attribution="&copy; OSM" url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"/>
        <BboxFetcher onBbox={setBbox}/>
        {points.map(p=>(
          <Marker key={p.id} position={[p.lat,p.lng]} icon={icon}>
            <Popup><b>{p.title}</b><br/>Тип: {p.type}{p.is_highlighted?" ⭐":""}</Popup>
          </Marker>
        ))}
      </MapContainer>

      <Box sx={{ position:"absolute", top:12, left:12 }} className="glass">
        <ToggleButtonGroup size="small" exclusive value={filter} onChange={(_,v)=>setFilter(v||"")} sx={{m:1}}>
          <ToggleButton value="">Все</ToggleButton>
          <ToggleButton value="spot">Споты</ToggleButton>
          <ToggleButton value="shop">Магазины</ToggleButton>
          <ToggleButton value="slip">Слипы</ToggleButton>
          <ToggleButton value="camp">Базы</ToggleButton>
        </ToggleButtonGroup>
      </Box>
    </Box>
  );
}
