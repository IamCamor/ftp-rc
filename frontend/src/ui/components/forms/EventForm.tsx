import React, { useState } from "react";
import { Grid, TextField, Button, Stack, Alert, Typography } from "@mui/material";
const API = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";

export default function EventForm(){
  const [f, setF] = useState({ title:"", region:"", starts_at:"", ends_at:"", description:"", location_lat:"", location_lng:"", link:"" });
  const [file, setFile] = useState<File|null>(null);
  const [msg, setMsg] = useState<string|null>(null); const [err,setErr]=useState<string|null>(null);
  const onChange = (e: any) => setF({ ...f, [e.target.name]: e.target.value });
  const submit = async () => {
    setMsg(null); setErr(null);
    try {
      const r = await fetch(API+"/events", { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(f) });
      if(!r.ok) throw new Error("Не удалось сохранить событие");
      const ev = await r.json();
      if (file) { const fd = new FormData(); fd.append("file", file); await fetch(API+`/events/${ev.id}/photo`,{ method:"POST", body: fd }); }
      setMsg("Событие сохранено");
    } catch(e:any){ setErr(e.message); }
  };
  return (
    <Stack spacing={2}>
      {msg && <Alert severity="success">{msg}</Alert>}
      {err && <Alert severity="error">{err}</Alert>}
      <Grid container spacing={2}>
        <Grid item xs={12} sm={6}><TextField label="Название" name="title" value={f.title} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={12} sm={6}><TextField label="Регион" name="region" value={f.region} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={12} sm={6}><TextField label="Начало (YYYY-MM-DD HH:mm)" name="starts_at" value={f.starts_at} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={12} sm={6}><TextField label="Окончание" name="ends_at" value={f.ends_at} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={12}><TextField label="Описание" name="description" value={f.description} onChange={onChange} fullWidth multiline minRows={3}/></Grid>
        <Grid item xs={6}><TextField label="Широта" name="location_lat" value={f.location_lat} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={6}><TextField label="Долгота" name="location_lng" value={f.location_lng} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={12}><TextField label="Ссылка" name="link" value={f.link} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={12}><Button variant="outlined" component="label">Фото<input type="file" hidden accept="image/*" onChange={e=>setFile(e.target.files?.[0]||null)} /></Button></Grid>
        {file && <Grid item xs={12}><Typography variant="body2">Файл: {file.name}</Typography></Grid>}
        <Grid item xs={12}><Button variant="contained" onClick={submit}>Сохранить</Button></Grid>
      </Grid>
    </Stack>
  );
}
