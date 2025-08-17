import { useEffect, useState } from "react";
import { Container, Typography, Stack, Card, CardContent, Button } from "@mui/material";
const API = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";

export default function SubscribeScreen(){
  const [plans,setPlans]=useState<any[]>([]);
  useEffect(()=>{ fetch(API+"/plans").then(r=>r.json()).then(setPlans); },[]);
  const buy = async (plan_id:string) => {
    const r = await fetch(API+"/create-checkout",{ method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify({ provider:"stripe", plan_id, mode:"subscription" }) });
    const j = await r.json(); if (j.checkout_url) window.location.href = j.checkout_url;
  };
  return (
    <Container sx={{py:3}}>
      <Typography variant="h5" gutterBottom>Подписка Pro</Typography>
      <Stack spacing={2}>
        {plans.map(p=>(
          <Card key={p.id}><CardContent>
            <Typography variant="h6">{p.title}</Typography>
            <Typography variant="body2" sx={{mb:1}}>{p.price} {p.currency} / {p.interval}</Typography>
            <Button variant="contained" onClick={()=>buy(p.id)}>Оформить</Button>
          </CardContent></Card>
        ))}
      </Stack>
    </Container>
  );
}
