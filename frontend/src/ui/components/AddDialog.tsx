import React from 'react'
import { Dialog, DialogTitle, DialogContent, DialogActions, Button, TextField, Tabs, Tab, Stack } from '@mui/material'
import { createMapPoint, createCatch, useMocks } from '../data/api'
type Props = { open: boolean, onClose: ()=>void }
export default function AddDialog({ open, onClose }: Props){
  const [tab, setTab] = React.useState(0)
  const [title, setTitle] = React.useState('Новая точка')
  const [lat, setLat] = React.useState(55.75)
  const [lng, setLng] = React.useState(37.62)
  const [species, setSpecies] = React.useState('Pike')
  const [weight, setWeight] = React.useState<number | ''>('')
  const [length, setLength] = React.useState<number | ''>('')
  const reset = () => { setTitle('Новая точка'); setLat(55.75); setLng(37.62); setSpecies('Pike'); setWeight(''); setLength('') }
  const submit = async () => {
    if (tab === 0){
      if (useMocks){ alert('Моки: точка сохранена локально'); onClose(); return }
      await createMapPoint({ title, lat, lng, type: 'spot', is_featured: false, visibility: 'public' })
      onClose(); reset()
    } else {
      if (useMocks){ alert('Моки: улов сохранён локально'); onClose(); return }
      await createCatch({ lat, lng, species, weight: Number(weight)||undefined, length: Number(length)||undefined })
      onClose(); reset()
    }
  }
  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>Добавить</DialogTitle>
      <DialogContent>
        <Tabs value={tab} onChange={(_,v)=>setTab(v)} sx={{ mb: 2 }}><Tab label="Точка" /><Tab label="Улов" /></Tabs>
        <Stack spacing={2}>
          {tab===0 ? (<>
            <TextField label="Название" value={title} onChange={e=>setTitle(e.target.value)} />
            <Stack direction="row" spacing={2}>
              <TextField label="Широта" value={lat} onChange={e=>setLat(Number(e.target.value))} type="number" />
              <TextField label="Долгота" value={lng} onChange={e=>setLng(Number(e.target.value))} type="number" />
            </Stack>
          </>):(<>
            <Stack direction="row" spacing={2}>
              <TextField label="Широта" value={lat} onChange={e=>setLat(Number(e.target.value))} type="number" />
              <TextField label="Долгота" value={lng} onChange={e=>setLng(Number(e.target.value))} type="number" />
            </Stack>
            <TextField label="Вид рыбы" value={species} onChange={e=>setSpecies(e.target.value)} />
            <Stack direction="row" spacing={2}>
              <TextField label="Вес (кг)" value={weight} onChange={e=>setWeight(e.target.value as any)} type="number" />
              <TextField label="Длина (см)" value={length} onChange={e=>setLength(e.target.value as any)} type="number" />
            </Stack>
          </>)}
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Отмена</Button>
        <Button variant="contained" onClick={submit}>Сохранить</Button>
      </DialogActions>
    </Dialog>
  )
}
