import React, { useEffect, useState } from "react";
import { Container, Typography, Paper, Button, Stack, Chip } from "@mui/material";
const API_BASE = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";
function authHeaders(json = true){ const t=localStorage.getItem("token"); const h:any = json?{ "Content-Type":"application/json"}:{}; if(t) h["Authorization"] = `Bearer ${t}`; return h; }

type Notif = { id:number; type:string; data?:any; is_read:boolean; created_at:string };

export default function NotificationsScreen() {
  const [items, setItems] = useState<Notif[]>([]);

  const load = async () => {
    const r = await fetch(`${API_BASE}/notifications`, { headers: authHeaders(false) });
    if (r.ok) {
      const j = await r.json();
      setItems(j.data || j);
    }
  };

  useEffect(() => { load(); }, []);

  const mark = async (id:number) => {
    const r = await fetch(`${API_BASE}/notifications/${id}/read`, { method:"POST", headers: authHeaders(false) });
    if (r.ok) load();
  };

  return (
    <Container sx={{ pt:3, pb:10 }}>
      <Typography variant="h5" gutterBottom>Уведомления</Typography>
      <Stack spacing={2}>
        {items.map(n => (
          <Paper key={n.id} sx={{ p:2, display: "flex", alignItems: "center", gap: 16 }}>
            <Chip label={n.type} color={n.is_read ? "default" : "primary"} variant={n.is_read?"outlined":"filled"} />
            <Typography variant="body2" sx={{ flex: 1 }}>{JSON.stringify(n.data)}</Typography>
            {!n.is_read && <Button onClick={() => mark(n.id)}>Отметить прочитанным</Button>}
          </Paper>
        ))}
      </Stack>
    </Container>
  );
}
