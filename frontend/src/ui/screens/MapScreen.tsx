import React from "react";
import { Container, Typography, Dialog, DialogTitle, DialogContent, DialogActions, Button, TextField, MenuItem, Stack, Alert } from "@mui/material";
import MapView from "../components/map/MapView";
const API = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";

export default function MapScreen(){
  const [open, setOpen] = React.useState(false);
  const [pos, setPos] = React.useState<{lat:number;lng:number}|null>(null);
  const [form, setForm] = React.useState({ title:"", category:"spot", description:"" });
  const [file, setFile] = React.useState<File|null>(null);
  const [msg,setMsg]=React.useState<string|null>(null); const [err,setErr]=React.useState<string|null>(null);
  const onAdd = (lat:number,lng:number) => { setPos({lat,lng}); setOpen(true); };
  const submit = async () => {
    setErr(null); setMsg(null);
    try{
      const res = await fetch(API+"/map/points",{ method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify({ ...form, lat: pos?.lat, lng: pos?.lng, is_public: true }) });
      if(!res.ok) throw new Error("Ошибка сохранения");
      const json = await res.json();
      if (file) {
        const fd = new FormData(); fd.append("file", file);
        await fetch(API+`/map/points/${json.id}/photo`, { method:"POST", body: fd });
      }
      setMsg("Точка отправлена на модерацию");
      setTimeout(()=>{ setOpen(false); }, 1200);
    }catch(e:any){ setErr(e.message); }
  };
  return (
    <Container sx={{py:3}}>
      <Typography variant="h5" gutterBottom>Карта</Typography>
      <MapView onAdd={onAdd}/>
      <Dialog open={open} onClose={()=>setOpen(false)}>
        <DialogTitle>Новая точка</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt:1 }}>
            {msg && <Alert severity="success">{msg}</Alert>}
            {err && <Alert severity="error">{err}</Alert>}
            <TextField label="Название" value={form.title} onChange={e=>setForm({...form, title:e.target.value})}/>
            <TextField label="Категория" select value={form.category} onChange={e=>setForm({...form, category:e.target.value})}>
              <MenuItem value="spot">Место</MenuItem>
              <MenuItem value="shop">Магазин</MenuItem>
              <MenuItem value="slip">Слип</MenuItem>
              <MenuItem value="resort">Турбаза</MenuItem>
            </TextField>
            <TextField label="Описание" multiline minRows={3} value={form.description} onChange={e=>setForm({...form, description:e.target.value})}/>
            <Button variant="outlined" component="label">Фото<input type="file" hidden accept="image/*" onChange={e=>setFile(e.target.files?.[0]||null)} /></Button>
            {file && <Typography variant="body2">Файл: {file.name}</Typography>}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setOpen(false)}>Отмена</Button>
          <Button variant="contained" onClick={submit}>Сохранить</Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
}
