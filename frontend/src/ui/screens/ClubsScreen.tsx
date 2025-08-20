import { useEffect, useState } from "react";
import { fetchClubs, createClub, Club } from "../data/api";
import { Button, Card, CardContent, Grid2 as Grid, Stack, TextField, Typography } from "@mui/material";
import LoadingOverlay from "../components/LoadingOverlay";
import ErrorAlert from "../components/ErrorAlert";

export default function ClubsScreen(){
  const [items,setItems]=useState<Club[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);
  const [creating,setCreating]=useState(false);
  const [form,setForm]=useState<Partial<Club>>({ name:"", description:"" });

  const load=async ()=>{ setLoading(true); setErr(null); try{ setItems(await fetchClubs()); }catch{ setErr("Не удалось загрузить клубы"); } finally{ setLoading(false); } };
  useEffect(()=>{ load(); },[]);

  const submit=async ()=>{ try{ await createClub(form); setCreating(false); setForm({ name:"", description:"" }); load(); }catch{ setErr("Не удалось создать клуб"); } };

  return (
    <Stack spacing={2}>
      <Stack direction="row" justifyContent="space-between" alignItems="center">
        <Typography variant="h5" color="white">Клубы</Typography>
        <Button variant="contained" onClick={()=>setCreating(true)}>Создать</Button>
      </Stack>
      {err && <ErrorAlert message={err}/>}
      {creating && (
        <Card className="glass"><CardContent>
          <Stack spacing={2}>
            <TextField label="Название" value={form.name||""} onChange={e=>setForm({...form,name:e.target.value})}/>
            <TextField label="Описание" value={form.description||""} onChange={e=>setForm({...form,description:e.target.value})}/>
            <Button variant="contained" onClick={submit}>Сохранить</Button>
          </Stack>
        </CardContent></Card>
      )}
      <Grid container spacing={2}>
        {items.map(c=>(
          <Grid size={{xs:12,md:6}} key={c.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{c.name}</Typography>
              <Typography color="#9aa4af">{c.description}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      <LoadingOverlay open={loading}/>
    </Stack>
  );
}
