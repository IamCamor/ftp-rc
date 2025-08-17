import React from 'react'
import { Tabs, Tab, Box, Stack, Button, Typography, TextField, Card, CardContent, CardActions } from '@mui/material'
import GlassCard from '../components/GlassCard'
import * as s2 from '../data/api_patch_s2'
type FeedItem = { id:number; species?:string; weight?:number; length?:number; lat:number; lng:number; likes?:number; comments?:{text:string}[] }
export default function FeedScreen(){
  const [tab, setTab] = React.useState<'global'|'local'|'follow'>('global')
  const [items, setItems] = React.useState<FeedItem[]>([])
  const [comment, setComment] = React.useState<Record<number,string>>({})
  const load = async () => {
    try {
      let data:any
      if (tab==='global') data = await s2.getFeedGlobal()
      if (tab==='local')  data = await s2.getFeedLocal(55.75, 37.62, 50)
      if (tab==='follow') data = await s2.getFeedFollow()
      data = (data?.data)||data
      setItems(data||[])
    } catch(e){ console.error(e) }
  }
  React.useEffect(()=>{ load() }, [tab])
  const like = async (id:number) => { try{ await s2.likeCatch(id); setItems(prev=>prev.map(x=>x.id===id?{...x,likes:(x.likes||0)+1}:x)) }catch(e){ console.error(e) } }
  const addComment = async (id:number) => { const text = comment[id]; if (!text) return; try{ await s2.commentCatch(id, text); setComment({...comment,[id]:''}) }catch(e){ console.error(e) } }
  return (
    <Box>
      <Tabs value={tab} onChange={(e,v)=>setTab(v)} sx={{ mb:2 }}>
        <Tab value="global" label="Global" />
        <Tab value="local"  label="Local" />
        <Tab value="follow" label="Follow" />
      </Tabs>
      <Stack spacing={2}>
        {items.map(it=>(
          <GlassCard key={it.id}>
            <Card elevation={0}>
              <CardContent>
                <Typography variant="h6">{it.species || 'Улов'} #{it.id}</Typography>
                <Typography variant="body2" color="text.secondary">
                  Вес: {it.weight||'-'} | Длина: {it.length||'-'} | Координаты: {it.lat?.toFixed?.(3)}, {it.lng?.toFixed?.(3)}
                </Typography>
              </CardContent>
              <CardActions><Button onClick={()=>like(it.id)}>Лайк {(it.likes||0)}</Button></CardActions>
              <Box sx={{ px:2, pb:2 }}>
                <Stack direction="row" spacing={1}>
                  <TextField size="small" fullWidth placeholder="Комментарий..." value={comment[it.id]||''} onChange={(e)=>setComment({...comment,[it.id]:e.target.value})} />
                  <Button onClick={()=>addComment(it.id)}>Отправить</Button>
                </Stack>
              </Box>
            </Card>
          </GlassCard>
        ))}
      </Stack>
    </Box>
  )
}