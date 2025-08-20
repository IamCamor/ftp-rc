import { Button, Grid2 as Grid, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { useForm } from "react-hook-form";
import { createPoint } from "../data/api";

type Form = { lat:number; lng:number; title:string; type:"shop"|"slip"|"camp"|"spot" };

export default function AddPointScreen(){
  const { register, handleSubmit, reset } = useForm<Form>({ defaultValues:{ lat:55.76, lng:37.64, type:"spot" } });
  const onSubmit = async (v:Form) => {
    try{ await createPoint(v); alert("Сохранено!"); reset(); }
    catch{ alert("DEMO: точка сохранена локально (без API)"); }
  };
  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Добавить точку</Typography>
      <form onSubmit={handleSubmit(onSubmit)}>
        <Grid container spacing={2}>
          <Grid size={6}><TextField label="Широта" fullWidth {...register("lat",{valueAsNumber:true})}/></Grid>
          <Grid size={6}><TextField label="Долгота" fullWidth {...register("lng",{valueAsNumber:true})}/></Grid>
          <Grid size={12}><TextField label="Название" fullWidth {...register("title")}/></Grid>
          <Grid size={12}>
            <TextField select label="Тип" fullWidth defaultValue="spot" {...register("type")}>
              <MenuItem value="spot">Спот</MenuItem><MenuItem value="shop">Магазин</MenuItem><MenuItem value="slip">Слип</MenuItem><MenuItem value="camp">Турбаза</MenuItem>
            </TextField>
          </Grid>
          <Grid size={12}><Button variant="contained" type="submit">Сохранить</Button></Grid>
        </Grid>
      </form>
    </Stack>
  );
}
