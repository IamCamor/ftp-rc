import React, { useEffect, useState } from "react";
import { Container, Typography, Tabs, Tab, Box, Button, Stack, Alert } from "@mui/material";

const API = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";
function authHeaders(){ const t = localStorage.getItem("token"); return t ? { Authorization: "Bearer " + t } : {}; }

export default function AdminScreen(){
  const [tab, setTab] = useState(0);
  return (
    <Container sx={{py:3}}>
      <Typography variant="h5" gutterBottom>Админка</Typography>
      <Tabs value={tab} onChange={(_,v)=>setTab(v)} sx={{mb:2}}>
        <Tab label="Модерация комментариев"/>
        <Tab label="Модерация точек"/>
        <Tab label="Пользователи/роли"/>
        <Tab label="Тест писем"/>
      </Tabs>
      {tab===0 && <ModerateComments/>}
      {tab===1 && <ModeratePoints/>}
      {tab===2 && <UsersRoles/>}
      {tab===3 && <MailTests/>}
    </Container>
  );
}

function ModerateComments(){
  const [items,setItems]=useState<any[]>([]); const [msg,setMsg]=useState<string|null>(null);
  const load=async()=>{ const r=await fetch(API+"/admin/comments/pending",{headers:authHeaders()}); setItems(await r.json()); };
  useEffect(()=>{load();},[]);
  const act = async (id:number, ok:boolean) => { await fetch(API+`/admin/comments/${id}/${ok?'approve':'reject'}`,{method:'POST',headers:authHeaders()}); setMsg(ok?'Одобрено':'Отклонено'); load(); };
  return <Box>{msg && <Alert severity="success">{msg}</Alert>}{items.map(c=>(<Stack key={c.id} direction="row" justifyContent="space-between" sx={{py:1, borderBottom:'1px solid #eee'}}><div>#{c.id}: {c.body}</div><div><Button onClick={()=>act(c.id,true)}>Одобрить</Button><Button color="warning" onClick={()=>act(c.id,false)}>Отклонить</Button></div></Stack>))}</Box>;
}

function ModeratePoints(){
  const [items,setItems]=useState<any[]>([]);
  const load=async()=>{ const r=await fetch(API+"/admin/points/pending",{headers:authHeaders()}); setItems(await r.json()); };
  useEffect(()=>{load();},[]);
  const act = async (id:number, ok:boolean) => { await fetch(API+`/admin/points/${id}/${ok?'approve':'reject'}`,{method:'POST',headers:authHeaders()}); load(); };
  return <Box>{items.map(p=>(<Stack key={p.id} direction="row" justifyContent="space-between" sx={{py:1, borderBottom:'1px solid #eee'}}><div>#{p.id}: {p.title} ({p.category})</div><div><Button onClick={()=>act(p.id,true)}>Одобрить</Button><Button color="warning" onClick={()=>act(p.id,false)}>Отклонить</Button></div></Stack>))}</Box>;
}

function UsersRoles(){
  const [items,setItems]=useState<any[]>([]);
  const load=async()=>{ const r=await fetch(API+"/admin/users",{headers:authHeaders()}); setItems(await r.json()); };
  useEffect(()=>{load();},[]);
  const makeAdmin = async (id:number) => { await fetch(API+`/admin/users/${id}/role`,{method:'POST',headers:{...authHeaders(),'Content-Type':'application/json'},body:JSON.stringify({role:'admin'})}); load(); };
  return <Box>{items.map(u=>(<Stack key={u.id} direction="row" justifyContent="space-between" sx={{py:1, borderBottom:'1px solid #eee'}}><div>#{u.id}: {u.name} — {u.roles}</div><div><Button onClick={()=>makeAdmin(u.id)}>Сделать админом</Button></div></Stack>))}</Box>;
}

function MailTests(){
  const send=async(t:string)=>{ await fetch(API+`/admin/mail/test/${t}`,{method:'POST',headers:authHeaders()}); alert('Отправлено (лог)'); };
  return <Stack direction="row" spacing={2}><Button onClick={()=>send('receipt')}>Квитанция</Button><Button onClick={()=>send('reminder')}>Напоминание</Button><Button onClick={()=>send('comment')}>Комментарий</Button></Stack>;
}
