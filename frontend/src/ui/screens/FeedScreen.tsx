import { useEffect, useState } from "react";
import { fetchFeed, CatchItem } from "../data/api";
import { Box, Chip, Grid2 as Grid, Stack, Typography, Card, CardContent, Avatar } from "@mui/material";

type Tab = "global" | "local" | "follow";
export default function FeedScreen(){
  const [tab,setTab] = useState<Tab>("global");
  const [items,setItems] = useState<CatchItem[]>([]);
  const [loading,setLoading] = useState(false);

  useEffect(()=>{ setLoading(true);
    const coords = tab==="local" ? { lat:55.76, lng:37.64 } : undefined;
    fetchFeed(tab,coords).then(setItems).catch(()=>setItems([
      { id:101, lat:55.7, lng:37.6, fish:"Щука", weight:3.2, user:{id:1,name:"Demo"}, created_at:new Date().toISOString() },
      { id:102, lat:59.9, lng:30.3, fish:"Окунь", weight:0.7, user:{id:2,name:"Test"} }
    ])).finally(()=>setLoading(false)); },[tab]);

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Лента</Typography>
      <Stack direction="row" spacing={1}>
        <Chip label="Global" color={tab==="global"?"primary":"default"} onClick={()=>setTab("global")} />
        <Chip label="Local"  color={tab==="local" ?"primary":"default"} onClick={()=>setTab("local")} />
        <Chip label="Follow" color={tab==="follow"?"primary":"default"} onClick={()=>setTab("follow")} />
      </Stack>
      <Grid container spacing={2}>
        {items.map(it=>(
          <Grid size={{xs:12,md:6}} key={it.id}>
            <Card className="glass"><CardContent>
              <Stack direction="row" spacing={2} alignItems="center">
                <Avatar>{(it.user?.name ?? "U").slice(0,1)}</Avatar>
                <Stack>
                  <Typography color="white">{it.user?.name ?? "Аноним"}</Typography>
                  <Typography variant="body2" color="#9aa4af">{new Date(it.created_at ?? Date.now()).toLocaleString()}</Typography>
                </Stack>
              </Stack>
              <Typography mt={2} color="white">
                Улов: {it.fish} {it.weight?`• ${it.weight} кг`: ""} {it.length?`• ${it.length} см`:""}
              </Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      {loading && <Typography color="#9aa4af">Загрузка…</Typography>}
    </Stack>
  );
}
