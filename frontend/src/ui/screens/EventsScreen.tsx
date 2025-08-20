import { useEffect, useState } from "react";
import { fetchEvents, createEvent, EventItem } from "../data/api";
import { Button, Card, CardContent, Grid2 as Grid, Stack, TextField, Typography } from "@mui/material";
import LoadingOverlay from "../components/LoadingOverlay";
import ErrorAlert from "../components/ErrorAlert";

export default function EventsScreen(){
  const [items,setItems]=useState<EventItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);
  const [creating,setCreating]=useState(false);
  const [form,setForm]=useState({ title:"", region:"", starts_at:"" });

  const load=async ()=>{ setLoading(true); setErr(null);
    try{ setItems(await fetchEvents()); } catch{ setErr("Не удалось загрузить события"); }
    finally{ setLoading(false); } };

  useEffect(()=>{ load(); },[]);

  const submit=async ()=>{ try{ await createEvent(form as any); setCreating(false); setForm({title:"",region:"",starts_at:""}); load(); }catch{ setErr("Не удалось создать событие"); } };

  return (
    <Stack spacing={2}>
      <Stack direction="row" justifyContent="space-between" alignItems="center">
        <Typography variant="h5" color="white">События</Typography>
        <Button variant="contained" onClick={()=>setCreating(true)}>Добавить</Button>
      </Stack>
      {err && <ErrorAlert message={err}/>}
      {creating && (
        <Card className="glass"><CardContent>
          <Stack spacing={2}>
            <TextField label="Название" value={form.title} onChange={e=>setForm({...form,title:e.target.value})}/>
            <TextField label="Регион" value={form.region} onChange={e=>setForm({...form,region:e.target.value})}/>
            <TextField label="Дата" type="datetime-local" value={form.starts_at} onChange={e=>setForm({...form,starts_at:e.target.value})}/>
            <Button variant="contained" onClick={submit}>Сохранить</Button>
          </Stack>
        </CardContent></Card>
      )}
      <Grid container spacing={2}>
        {items.map(ev=>(
          <Grid size={{xs:12,md:6}} key={ev.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{ev.title}</Typography>
              <Typography color="#9aa4af">{ev.region}</Typography>
              <Typography color="#9aa4af">{ev.starts_at && new Date(ev.starts_at).toLocaleString()}</Typography>
              <Typography color="white">{ev.description}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      <LoadingOverlay open={loading}/>
    </Stack>
  );
}
