import React from 'react'
import { Grid, Typography, Stack, Chip, Box, Fab } from '@mui/material'
import AddLocationAltIcon from '@mui/icons-material/AddLocationAlt'
import GlassCard from '../components/GlassCard'
import MapboxMap from '../components/MapboxMap'
import AddCatchDialog, { CatchForm } from '../components/AddCatchDialog'
import { addPointLocal } from '../data/api'

const TYPE_KEYS = ['shop','slip','base','spot','catch'] as const
type TType = typeof TYPE_KEYS[number]

export default function MapScreen(){
  const [selected, setSelected] = React.useState<TType[]>([])
  const [featured, setFeatured] = React.useState<boolean | undefined>(undefined)
  const [dialogOpen, setDialogOpen] = React.useState(false)
  const [clickedCoords, setClickedCoords] = React.useState<{lat:number;lng:number}|undefined>()

  const toggleType = (t: TType) => setSelected(prev => prev.includes(t) ? prev.filter(x=>x!==t) : [...prev, t])
  const toggleFeatured = () => setFeatured(prev => prev === true ? undefined : true)

  const onAdd = (v: CatchForm) => {
    addPointLocal({ title:v.title, lat:v.lat, lng:v.lng, type:v.type, is_featured:false, visibility:'public' })
    setDialogOpen(false)
  }

  return (
    <>
    <Grid container spacing={2}>
      <Grid item xs={12} md={8}>
        <MapboxMap filter={{ types: selected, featured }} onMapClick={(c)=>{ setClickedCoords(c); }} />
      </Grid>
      <Grid item xs={12} md={4}>
        <GlassCard>
          <Typography variant="h6" gutterBottom>Фильтры</Typography>
          <Stack direction="row" spacing={1} flexWrap="wrap">
            <Chip label="Магазины" variant={selected.includes('shop')?'filled':'outlined'} onClick={()=>toggleType('shop')} />
            <Chip label="Слипы"    variant={selected.includes('slip')?'filled':'outlined'} onClick={()=>toggleType('slip')} />
            <Chip label="Турбазы"  variant={selected.includes('base')?'filled':'outlined'} onClick={()=>toggleType('base')} />
            <Chip label="Точки"    variant={selected.includes('spot')?'filled':'outlined'} onClick={()=>toggleType('spot')} />
            <Chip label="Уловы"    variant={selected.includes('catch')?'filled':'outlined'} onClick={()=>toggleType('catch')} />
            <Chip label={featured ? 'Только выделенные' : 'Все'} color="secondary" variant={featured?'filled':'outlined'} onClick={toggleFeatured} />
          </Stack>
          <Box mt={2}><Typography variant="body2" color="text.secondary">
            Клик по карте запоминает координаты для быстрого добавления.
          </Typography></Box>
        </GlassCard>
      </Grid>
    </Grid>
    <Fab color="primary" className="fab" onClick={()=> setDialogOpen(true)}><AddLocationAltIcon/></Fab>
    <AddCatchDialog open={dialogOpen} onClose={()=>setDialogOpen(false)} coords={clickedCoords} onSubmit={onAdd} />
    </>
  )
}
