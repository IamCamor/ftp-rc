import React from 'react'
import GlassCard from '../components/GlassCard'
import { Typography, Stack, Button, Chip } from '@mui/material'
import * as s2 from '../data/api_patch_s2'
export default function AdminScreen(){
  const [items, setItems] = React.useState<any[]>([])
  const load = async ()=>{ try{ const r = await s2.moderationList(); setItems(r||[]) }catch(e){ console.error(e)} }
  React.useEffect(()=>{ load() },[])
  const approve = async (id:number)=>{ await s2.moderationApprove(id); load() }
  const reject  = async (id:number)=>{ await s2.moderationReject(id); load() }
  return (
    <GlassCard>
      <Typography variant="h6" gutterBottom>Модерация</Typography>
      <Stack spacing={1}>
        {items.map(it=>(
          <GlassCard key={it.id}>
            <Typography>#{it.id} [{it.type}] — статус: <Chip size="small" label={it.status} /></Typography>
            <Stack direction="row" spacing={1} sx={{ mt:1 }}>
              <Button variant="contained" onClick={()=>approve(it.id)}>Approve</Button>
              <Button variant="outlined" color="error" onClick={()=>reject(it.id)}>Reject</Button>
            </Stack>
          </GlassCard>
        ))}
        {!items.length && <Typography color="text.secondary">Очередь пуста</Typography>}
      </Stack>
    </GlassCard>
  )
}