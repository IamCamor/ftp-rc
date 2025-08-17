import React, { useEffect, useState } from "react";
import { Container, Typography, Paper, TextField, Button, Stack, Alert, Grid, Card, CardContent } from "@mui/material";
const API_BASE = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";
function authHeaders(json = true){ const t=localStorage.getItem("token"); const h:any = json?{ "Content-Type":"application/json"}:{}; if(t) h["Authorization"] = `Bearer ${t}`; return h; }

type EventItem = { id:number; title:string; description?:string; starts_at:string; region?:string };

export default function EventsScreen() {
  const [items, setItems] = useState<EventItem[]>([]);
  const [title, setTitle] = useState("");
  const [desc, setDesc] = useState("");
  const [date, setDate] = useState("");
  const [region, setRegion] = useState("");
  const [msg, setMsg] = useState<string|null>(null);
  const [err, setErr] = useState<string|null>(null);

  const load = async () => {
    try {
      const r = await fetch(`${API_BASE}/events`);
      const j = await r.json();
      setItems(j.data || j);
    } catch(e:any) { setErr(e.message); }
  };
  useEffect(() => { load(); }, []);

  const create = async () => {
    setMsg(null); setErr(null);
    try {
      const r = await fetch(`${API_BASE}/events`, {
        method: "POST",
        headers: authHeaders(true),
        body: JSON.stringify({ title, description: desc, starts_at: date, region })
      });
      if (!r.ok) throw new Error("Не удалось создать событие (нужна авторизация?)");
      setTitle(""); setDesc(""); setDate(""); setRegion("");
      setMsg("Событие создано");
      load();
    } catch(e:any) { setErr(e.message); }
  };

  return (
    <Container sx={{ pt:3, pb:10 }}>
      <Typography variant="h5" gutterBottom>События</Typography>
      {msg && <Alert severity="success">{msg}</Alert>}
      {err && <Alert severity="error">{err}</Alert>}
      <Paper sx={{ p:2, mb:3 }}>
        <Stack spacing={2}>
          <TextField label="Название" value={title} onChange={e=>setTitle(e.target.value)} />
          <TextField label="Описание" value={desc} onChange={e=>setDesc(e.target.value)} multiline minRows={2} />
          <TextField label="Дата и время (YYYY-MM-DD HH:mm)" value={date} onChange={e=>setDate(e.target.value)} />
          <TextField label="Регион" value={region} onChange={e=>setRegion(e.target.value)} />
          <Button variant="contained" onClick={create}>Создать событие</Button>
        </Stack>
      </Paper>

      <Grid container spacing={2}>
        {items.map(ev => (
          <Grid item xs={12} md={6} key={ev.id}>
            <Card>
              <CardContent>
                <Typography variant="h6">{ev.title}</Typography>
                <Typography variant="body2" color="text.secondary">{ev.description || "—"}</Typography>
                <Typography variant="caption">{ev.starts_at} · {ev.region || "—"}</Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Container>
  );
}
