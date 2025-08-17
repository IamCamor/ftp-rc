import React, { useEffect, useState } from "react";
import { Container, Typography, Paper, TextField, Button, Stack, Alert, Grid, Card, CardContent } from "@mui/material";
const API_BASE = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";
function authHeaders(json = true){ const t=localStorage.getItem("token"); const h:any = json?{ "Content-Type":"application/json"}:{}; if(t) h["Authorization"] = `Bearer ${t}`; return h; }

type Club = { id:number; name:string; description?:string; members_count?:number };

export default function ClubsScreen() {
  const [clubs, setClubs] = useState<Club[]>([]);
  const [name, setName] = useState("");
  const [desc, setDesc] = useState("");
  const [msg, setMsg] = useState<string|null>(null);
  const [err, setErr] = useState<string|null>(null);

  const load = async () => {
    try {
      const r = await fetch(`${API_BASE}/clubs`);
      const j = await r.json();
      setClubs(j.data || j);
    } catch(e:any) { setErr(e.message); }
  };

  useEffect(() => { load(); }, []);

  const create = async () => {
    setMsg(null); setErr(null);
    try {
      const r = await fetch(`${API_BASE}/clubs`, {
        method: "POST",
        headers: authHeaders(true),
        body: JSON.stringify({ name, description: desc })
      });
      if (!r.ok) throw new Error("Не удалось создать клуб (нужна авторизация?)");
      setName(""); setDesc("");
      setMsg("Клуб создан");
      load();
    } catch(e:any) { setErr(e.message); }
  };

  return (
    <Container sx={{ pt:3, pb:10 }}>
      <Typography variant="h5" gutterBottom>Клубы</Typography>
      {msg && <Alert severity="success">{msg}</Alert>}
      {err && <Alert severity="error">{err}</Alert>}
      <Paper sx={{ p:2, mb:3 }}>
        <Stack spacing={2}>
          <TextField label="Название клуба" value={name} onChange={e=>setName(e.target.value)} />
          <TextField label="Описание" value={desc} onChange={e=>setDesc(e.target.value)} multiline minRows={2} />
          <Button variant="contained" onClick={create}>Создать клуб</Button>
        </Stack>
      </Paper>

      <Grid container spacing={2}>
        {clubs.map(c => (
          <Grid item xs={12} md={6} key={c.id}>
            <Card>
              <CardContent>
                <Typography variant="h6">{c.name}</Typography>
                <Typography variant="body2" color="text.secondary">{c.description || "—"}</Typography>
                <Typography variant="caption">Участников: {c.members_count ?? "?"}</Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Container>
  );
}
