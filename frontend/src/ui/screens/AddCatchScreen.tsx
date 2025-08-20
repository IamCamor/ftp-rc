import { useState } from "react";
import { Button, Card, CardContent, Grid2 as Grid, MenuItem, Stack, TextField, Typography, Alert } from "@mui/material";
import { createCatch, uploadImage } from "../data/api";

export default function AddCatchScreen(){
  const [form,setForm]=useState({ lat:"", lng:"", fish:"", weight:"", length:"", style:"shore" });
  const [photo,setPhoto]=useState<File|null>(null);
  const [status,setStatus]=useState<"idle"|"ok"|"err">("idle");
  const [err,setErr]=useState<string|null>(null);

  const submit=async ()=>{
    try{
      setErr(null); setStatus("idle");
      let photo_id:number|undefined;
      if (photo){ const m=await uploadImage(photo); photo_id=m.id; }
      const payload = {
        lat:parseFloat(form.lat), lng:parseFloat(form.lng),
        fish:form.fish, weight: form.weight?parseFloat(form.weight):undefined,
        length: form.length?parseFloat(form.length):undefined,
        style: form.style, privacy:'all', photo_id
      };
      await createCatch(payload as any);
      setStatus("ok");
      setForm({ lat:"", lng:"", fish:"", weight:"", length:"", style:"shore" }); setPhoto(null);
    }catch{ setErr("Не удалось добавить улов"); setStatus("err"); }
  };

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Добавить улов</Typography>
      {status==="ok" && <Alert severity="success">Сохранено</Alert>}
      {status==="err" && <Alert severity="error">{err}</Alert>}
      <Card className="glass"><CardContent>
        <Grid container spacing={2}>
          <Grid size={{xs:12,md:6}}>
            <TextField fullWidth label="Широта" value={form.lat} onChange={e=>setForm({...form,lat:e.target.value})}/>
          </Grid>
          <Grid size={{xs:12,md:6}}>
            <TextField fullWidth label="Долгота" value={form.lng} onChange={e=>setForm({...form,lng:e.target.value})}/>
          </Grid>
          <Grid size={{xs:12,md:6}}>
            <TextField fullWidth label="Рыба" value={form.fish} onChange={e=>setForm({...form,fish:e.target.value})}/>
          </Grid>
          <Grid size={{xs:6,md:3}}>
            <TextField fullWidth label="Вес, кг" value={form.weight} onChange={e=>setForm({...form,weight:e.target.value})}/>
          </Grid>
          <Grid size={{xs:6,md:3}}>
            <TextField fullWidth label="Длина, см" value={form.length} onChange={e=>setForm({...form,length:e.target.value})}/>
          </Grid>
          <Grid size={12}>
            <TextField select label="Способ" value={form.style} onChange={e=>setForm({...form,style:e.target.value})}>
              {["shore","boat","ice"].map(s=><MenuItem key={s} value={s}>{s}</MenuItem>)}
            </TextField>
          </Grid>
          <Grid size={12}>
            <Button variant="outlined" component="label">
              Фото
              <input type="file" hidden accept="image/*" onChange={e=>setPhoto(e.target.files?.[0]||null)}/>
            </Button>
          </Grid>
          <Grid size={12}>
            <Button variant="contained" onClick={submit}>Сохранить</Button>
          </Grid>
        </Grid>
      </CardContent></Card>
    </Stack>
  );
}
