import { useState } from "react";
import { Box, Button, Card, CardContent, MenuItem, Stack, TextField, Typography, Alert } from "@mui/material";
import { createPoint, uploadImage } from "../data/api";

export default function AddPointScreen(){
  const [form,setForm]=useState({ title:"", type:"spot", lat:"", lng:"" });
  const [photo,setPhoto]=useState<File|null>(null);
  const [status,setStatus]=useState<"idle"|"ok"|"err">("idle");
  const [err,setErr]=useState<string|null>(null);

  const submit=async ()=>{
    try{
      setErr(null); setStatus("idle");
      let photo_id:number|undefined;
      if (photo){ const m = await uploadImage(photo); photo_id = m.id; }
      const payload = { ...form, lat:parseFloat(form.lat), lng:parseFloat(form.lng), photo_id };
      await createPoint(payload as any);
      setStatus("ok"); setForm({ title:"", type:"spot", lat:"", lng:"" }); setPhoto(null);
    }catch(e:any){ setErr("Не удалось добавить точку"); setStatus("err"); }
  };

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Добавить точку</Typography>
      {status==="ok" && <Alert severity="success">Сохранено</Alert>}
      {status==="err" && <Alert severity="error">{err}</Alert>}
      <Card className="glass"><CardContent>
        <Stack spacing={2}>
          <TextField label="Название" value={form.title} onChange={e=>setForm({...form,title:e.target.value})}/>
          <TextField select label="Тип" value={form.type} onChange={e=>setForm({...form,type:e.target.value})}>
            {["spot","shop","slip","camp","catch"].map(t=><MenuItem key={t} value={t}>{t}</MenuItem>)}
          </TextField>
          <Box sx={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:2}}>
            <TextField label="Широта" value={form.lat} onChange={e=>setForm({...form,lat:e.target.value})}/>
            <TextField label="Долгота" value={form.lng} onChange={e=>setForm({...form,lng:e.target.value})}/>
          </Box>
          <Button variant="outlined" component="label">
            Фото
            <input type="file" hidden accept="image/*" onChange={e=>setPhoto(e.target.files?.[0]||null)}/>
          </Button>
          <Button variant="contained" onClick={submit}>Сохранить</Button>
        </Stack>
      </CardContent></Card>
    </Stack>
  );
}
