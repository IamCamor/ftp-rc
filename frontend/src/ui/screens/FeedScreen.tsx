import { useEffect, useState } from "react";
import { fetchFeedGlobal, CatchItem } from "../data/api";
import { Grid2 as Grid, Stack, Typography, Card, CardContent } from "@mui/material";
import LoadingOverlay from "../components/LoadingOverlay";
import ErrorAlert from "../components/ErrorAlert";

export default function FeedScreen(){
  const [items,setItems]=useState<CatchItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);

  useEffect(()=>{ let alive=true; (async ()=>{ setLoading(true);
    try{ const data = await fetchFeedGlobal(); if(alive) setItems(data); }
    catch{ setErr("Не удалось загрузить ленту"); }
    finally{ setLoading(false); }
  })(); return ()=>{ alive=false; }; },[]);

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Лента</Typography>
      {err && <ErrorAlert message={err}/>}
      <Grid container spacing={2}>
        {items.map(it=>(
          <Grid size={{xs:12,md:6}} key={it.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{it.fish}</Typography>
              <Typography color="#9aa4af">
                {it.weight?`Вес: ${it.weight} кг  `:""}{it.length?`Длина: ${it.length} см`:""} {it.style?` • ${it.style}`:""}
              </Typography>
              {it.photo?.url && <img src={it.photo.url} style={{width:"100%",marginTop:8,borderRadius:12}}/>}
              <Typography color="#9aa4af" variant="caption">{it.created_at && new Date(it.created_at).toLocaleString()}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      <LoadingOverlay open={loading}/>
    </Stack>
  );
}
