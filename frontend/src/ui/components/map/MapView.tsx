import React, { useEffect, useMemo, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import MarkerClusterGroup from "react-leaflet-cluster";
import { Box, Chip, Stack, CircularProgress, Fab, Tooltip, Switch, FormControlLabel } from "@mui/material";
import AddLocationAltIcon from "@mui/icons-material/AddLocationAlt";

const API = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";

const icon = new L.Icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  shadowSize: [41, 41]
});

type Point = { id:number; lat:number; lng:number; title:string; description?:string; category:string; is_public:boolean; is_highlighted:boolean; photo_url?:string|null };

export default function MapView({ onAdd }: { onAdd?: (lat:number, lng:number) => void }) {
  const [data, setData] = useState<Point[]>([]);
  const [loading, setLoading] = useState(true);
  const [cat, setCat] = useState<string | null>(null);
  const [cluster, setCluster] = useState(true);

  useEffect(() => {
    (async () => {
      setLoading(true);
      const url = new URL(API + "/map/points");
      if (cat) url.searchParams.set("category", cat);
      const r = await fetch(url.toString());
      const j = await r.json();
      setData(j); setLoading(false);
    })();
  }, [cat]);

  const center = useMemo<[number,number]>(() => data.length ? [data[0].lat, data[0].lng] : [55.751244, 37.618423], [data]);

  const Markers = () => <>
    {data.map(p => (
      <Marker key={p.id} position={[p.lat, p.lng]} icon={icon}>
        <Popup>
          <b>{p.title}</b><br/>
          {p.description || "—"}<br/>
          Категория: {p.category}<br/>
          {p.is_highlighted ? "⭐ Выделенная точка" : ""}<br/>
          {p.photo_url ? <img src={p.photo_url} alt="" style={{width:180, marginTop:6, borderRadius:8}}/> : null}
        </Popup>
      </Marker>
    ))}
  </>;

  return (
    <Box sx={{ position: "relative", height: "70vh", borderRadius: 2, overflow: "hidden" }}>
      {loading && <Box sx={{ position:"absolute", inset:0, display:"grid", placeItems:"center", zIndex: 1000 }}><CircularProgress /></Box>}
      <MapContainer center={center} zoom={11} style={{ height: "100%", width: "100%" }}>
        <TileLayer attribution='&copy; OpenStreetMap contributors' url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        {cluster ? <MarkerClusterGroup maxClusterRadius={48}><Markers/></MarkerClusterGroup> : <Markers/>}
      </MapContainer>

      <Stack direction="row" spacing={1} sx={{ position:"absolute", top: 12, left: 12, zIndex: 1100, bgcolor: "background.paper", p:1, borderRadius: 2 }}>
        {["all","spot","shop","slip","resort"].map(c => (
          <Chip key={c} label={c === "all" ? "Все" : c} color={!cat && c==="all" ? "primary" : (cat===c ? "primary" : "default")} onClick={() => setCat(c==="all"?null:c)} />
        ))}
        <FormControlLabel control={<Switch checked={cluster} onChange={(_,v)=>setCluster(v)}/>} label="Кластеризация" sx={{ml:1}} />
      </Stack>

      {!!onAdd && (
        <Tooltip title="Добавить точку">
          <Fab color="primary" sx={{ position:"absolute", right: 16, bottom: 16, zIndex: 1100 }} onClick={() => {
            if (!navigator.geolocation) return onAdd(55.751244, 37.618423);
            navigator.geolocation.getCurrentPosition(pos => onAdd(pos.coords.latitude, pos.coords.longitude), () => onAdd(55.751244, 37.618423));
          }}>
            <AddLocationAltIcon />
          </Fab>
        </Tooltip>
      )}
    </Box>
  );
}
