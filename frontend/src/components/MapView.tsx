import React, { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// фиксим иконки leaflet (без webpack loaders)
const icon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  shadowSize: [41, 41],
  shadowAnchor: [12, 41],
});

function FitBounds({ bbox }: { bbox?: [number,number,number,number] }) {
  const map = useMap();
  useEffect(()=>{
    if (!bbox) return;
    const [[minLat,minLng],[maxLat,maxLng]] = [[bbox[1],bbox[0]],[bbox[3],bbox[2]]];
    map.fitBounds([[minLat,minLng],[maxLat,maxLng]], { padding:[24,24] });
  },[bbox]);
  return null;
}

type Point = {
  id:number; title:string; lat:number; lng:number; category?:string;
};
export default function MapView({
  points, center=[55.751244,37.618423], zoom=11, bbox
}:{ points:Point[]; center?:[number,number]; zoom?:number; bbox?:[number,number,number,number]}) {
  return (
    <div className="relative w-full h-full">
      <MapContainer
        center={center}
        zoom={zoom}
        className="w-full h-full rounded-2xl overflow-hidden"
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; CARTO & OpenStreetMap'
          url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
        />
        {points.map(p=>(
          <Marker key={p.id} position={[p.lat, p.lng]} icon={icon}>
            <Popup>
              <div className="text-sm">
                <div className="font-semibold">{p.title || 'Точка'}</div>
                {p.category && <div className="text-xs text-gray-500 mt-1">Категория: {p.category}</div>}
              </div>
            </Popup>
          </Marker>
        ))}
        <FitBounds bbox={bbox}/>
      </MapContainer>
    </div>
  );
}
