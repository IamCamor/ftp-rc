import React, { useState } from "react";
import { Grid, TextField, Button, Stack, Alert, Typography } from "@mui/material";
const API = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";

export default function ClubForm(){
  const [f, setF] = useState({ name:"", region:"", description:"" });
  const [file, setFile] = useState<File|null>(null);
  const [msg, setMsg] = useState<string|null>(null); const [err,setErr]=useState<string|null>(null);
  const onChange = (e: any) => setF({ ...f, [e.target.name]: e.target.value });
  const submit = async () => {
    setMsg(null); setErr(null);
    try {
      const r = await fetch(API+"/clubs", { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(f) });
      if(!r.ok) throw new Error("Не удалось сохранить клуб");
      const club = await r.json();
      if (file) { const fd = new FormData(); fd.append("file", file); await fetch(API+`/clubs/${club.id}/logo`,{ method:"POST", body: fd }); }
      setMsg("Клуб сохранён");
    } catch(e:any){ setErr(e.message); }
  };
  return (
    <Stack spacing={2}>
      {msg && <Alert severity="success">{msg}</Alert>}
      {err && <Alert severity="error">{err}</Alert>}
      <Grid container spacing={2}>
        <Grid item xs={12} sm={6}><TextField label="Название" name="name" value={f.name} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={12} sm={6}><TextField label="Регион" name="region" value={f.region} onChange={onChange} fullWidth/></Grid>
        <Grid item xs={12}><TextField label="Описание" name="description" value={f.description} onChange={onChange} fullWidth multiline minRows={3}/></Grid>
        <Grid item xs={12}><Button variant="outlined" component="label">Логотип<input type="file" hidden accept="image/*" onChange={e=>setFile(e.target.files?.[0]||null)} /></Button></Grid>
        {file && <Grid item xs={12}><Typography variant="body2">Файл: {file.name}</Typography></Grid>}
        <Grid item xs={12}><Button variant="contained" onClick={submit}>Сохранить</Button></Grid>
      </Grid>
    </Stack>
  );
}
