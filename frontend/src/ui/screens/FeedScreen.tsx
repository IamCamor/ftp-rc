import { useEffect, useState } from "react";
import { fetchFeedGlobal, fetchFeedLocal, CatchItem } from "../data/api";
import { Box, Chip, Grid2 as Grid, Stack, Typography, Card, CardContent } from "@mui/material";
import LoadingOverlay from "../components/LoadingOverlay";
import ErrorAlert from "../components/ErrorAlert";

type Tab = "global" | "local";
export default function FeedScreen(){
  const [tab,setTab]=useState<Tab>("global");
  const [items,setItems]=useState<CatchItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);

  useEffect(()=>{ let alive=true; (async ()=>{
    setLoading(true); setErr(null);
    try{
      const data = tab==="global" ? await fetchFeedGlobal() : await fetchFeedLocal(55.76,37.64);
      if(alive) setItems(data);
    }catch(e:any){ setErr("Не удалось загрузить ленту"); }
    finally{ setLoading(false); }
  })(); return ()=>{ alive=false; }; },[tab]);

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Лента</Typography>
      <Stack direction="row" spacing={1}>
        <Chip label="Global" color={tab==="global"?"primary":"default"} onClick={()=>setTab("global")} />
        <Chip label="Local"  color={tab==="local" ?"primary":"default"} onClick={()=>setTab("local")} />
      </Stack>
      {err && <ErrorAlert message={err}/>}
      <Grid container spacing={2}>
        {items.map(it=>(
          <Grid size={{xs:12,md:6}} key={it.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{it.fish}</Typography>
              <Typography color="#9aa4af">{it.weight?`Вес: ${it.weight} кг  `:""}{it.length?`Длина: ${it.length} см`:""}</Typography>
              <Typography color="#9aa4af">{new Date(it.created_at ?? Date.now()).toLocaleString()}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      <LoadingOverlay open={loading}/>
    </Stack>
  );
}
