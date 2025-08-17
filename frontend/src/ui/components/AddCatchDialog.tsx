import React from 'react'
import { Dialog, DialogTitle, DialogContent, DialogActions, Button, TextField, Stack, MenuItem } from '@mui/material'

export type CatchForm = { title:string; species:string; weight?:number; length?:number; lat:number; lng:number; type:'spot'|'catch'|'shop'|'slip'|'base' }

export default function AddCatchDialog({ open, onClose, onSubmit, coords }:{ open:boolean; onClose:()=>void; onSubmit:(v:CatchForm)=>void; coords?:{lat:number;lng:number} }){
  const [title,setTitle]=React.useState('Новый улов')
  const [species,setSpecies]=React.useState('Pike')
  const [weight,setWeight]=React.useState<number|undefined>()
  const [length,setLength]=React.useState<number|undefined>()
  const [type,setType]=React.useState<CatchForm['type']>('catch')
  React.useEffect(()=>{ if(coords){ /* could prefill */ } },[coords])
  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>Добавить улов / точку</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{mt:1}}>
          <TextField label="Заголовок" value={title} onChange={e=>setTitle(e.target.value)} />
          <TextField select label="Тип" value={type} onChange={e=>setType(e.target.value as any)}>
            <MenuItem value="catch">Улов</MenuItem>
            <MenuItem value="spot">Точка</MenuItem>
            <MenuItem value="shop">Магазин</MenuItem>
            <MenuItem value="slip">Слип</MenuItem>
            <MenuItem value="base">Турбаза</MenuItem>
          </TextField>
          <TextField label="Вид рыбы" value={species} onChange={e=>setSpecies(e.target.value)} helperText="Например: Pike, Carp" />
          <Stack direction="row" spacing={2}>
            <TextField type="number" label="Вес (кг)" value={weight??''} onChange={e=>setWeight(e.target.value?Number(e.target.value):undefined)} />
            <TextField type="number" label="Длина (см)" value={length??''} onChange={e=>setLength(e.target.value?Number(e.target.value):undefined)} />
          </Stack>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Отмена</Button>
        <Button onClick={()=> onSubmit({ title, species, weight, length, lat: coords?.lat??55.75, lng: coords?.lng??37.62, type })} variant="contained">Сохранить</Button>
      </DialogActions>
    </Dialog>
  )
}
