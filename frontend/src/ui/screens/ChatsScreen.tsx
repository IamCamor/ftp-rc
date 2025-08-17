import React, { useEffect, useState } from "react";
import { Container, Typography, Paper, TextField, Button, Stack, Alert, Grid, List, ListItemText, Divider, ListItemButton } from "@mui/material";
const API_BASE = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";
function authHeaders(json = true){ const t=localStorage.getItem("token"); const h:any = json?{ "Content-Type":"application/json"}:{}; if(t) h["Authorization"] = `Bearer ${t}`; return h; }

type Room = { id:number; title?:string; is_group?:boolean };
type Message = { id:number; user_id:number; text:string; created_at:string };

export default function ChatsScreen() {
  const [rooms, setRooms] = useState<Room[]>([]);
  const [active, setActive] = useState<Room | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState("");
  const [err, setErr] = useState<string|null>(null);

  const loadRooms = async () => {
    try {
      const r = await fetch(`${API_BASE}/chats`, { headers: authHeaders(false) });
      if (!r.ok) throw new Error("Нужна авторизация для чатов");
      setRooms(await r.json());
    } catch(e:any) { setErr(e.message); }
  };

  const loadMessages = async (roomId:number) => {
    try {
      const r = await fetch(`${API_BASE}/chats/${roomId}/messages`, { headers: authHeaders(false) });
      if (r.ok) setMessages(await r.json());
    } catch {}
  };

  useEffect(() => { loadRooms(); }, []);

  const openRoom = (r:Room) => { setActive(r); setMessages([]); loadMessages(r.id); };

  const send = async () => {
    if (!active || !text.trim()) return;
    try {
      const r = await fetch(`${API_BASE}/chats/${active.id}/send`, {
        method: "POST",
        headers: authHeaders(true),
        body: JSON.stringify({ text })
      });
      if (r.ok) { setText(""); loadMessages(active.id); }
    } catch {}
  };

  return (
    <Container sx={{ pt:3, pb:10 }}>
      <Typography variant="h5" gutterBottom>Чаты</Typography>
      {err && <Alert severity="error">{err}</Alert>}
      <Grid container spacing={2}>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p:1 }}>
            <List dense>
              {rooms.map(r => (
                <ListItemButton key={r.id} onClick={() => openRoom(r)} selected={active?.id===r.id}>
                  <ListItemText primary={r.title || ("Room #"+r.id)} secondary={r.is_group ? "Group" : "Direct"} />
                </ListItemButton>
              ))}
            </List>
          </Paper>
        </Grid>
        <Grid item xs={12} md={8}>
          <Paper sx={{ p:2, minHeight: 300 }}>
            <Typography variant="subtitle1" gutterBottom>
              {active ? (active.title || ("Room #"+active.id)) : "Выберите чат"}
            </Typography>
            <Divider sx={{ mb:2 }} />
            <div style={{ maxHeight: 300, overflow: "auto", paddingRight: 8 }}>
              {messages.map(m => (
                <div key={m.id} style={{ marginBottom: 8 }}>
                  <Typography variant="body2">{m.text}</Typography>
                  <Typography variant="caption" color="text.secondary">{m.created_at}</Typography>
                </div>
              ))}
            </div>
            {active && (
              <Stack direction="row" spacing={1} sx={{ mt:2 }}>
                <TextField fullWidth size="small" value={text} onChange={e=>setText(e.target.value)} placeholder="Сообщение..." />
                <Button variant="contained" onClick={send}>Отправить</Button>
              </Stack>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Container>
  );
}
