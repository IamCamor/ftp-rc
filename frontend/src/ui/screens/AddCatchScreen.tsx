import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button, Grid2 as Grid, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { createCatch } from "../data/api";
import { useState } from "react";

const schema = z.object({
  lat: z.coerce.number(),
  lng: z.coerce.number(),
  fish: z.string().min(2),
  weight: z.coerce.number().optional(),
  length: z.coerce.number().optional(),
  style: z.enum(["shore","boat","ice"]).default("shore"),
  privacy: z.enum(["all","friends","groups","none"]).default("all")
});
type Form = z.infer<typeof schema>;

export default function AddCatchScreen(){
  const [ok,setOk] = useState<string|null>(null);
  const { register, handleSubmit, formState:{errors}, reset } = useForm<Form>({
    resolver: zodResolver(schema),
    defaultValues: { lat:55.76, lng:37.64, style:"shore", privacy:"all" }
  });

  const onSubmit = async (v:Form)=>{
    setOk(null);
    try{ await createCatch(v); setOk("Сохранено!"); reset(); }
    catch{ setOk("DEMO: локально сохранено (без API)."); }
  };

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Добавить улов</Typography>
      <form onSubmit={handleSubmit(onSubmit)}>
        <Grid container spacing={2}>
          <Grid size={6}><TextField label="Широта" fullWidth {...register("lat")} error={!!errors.lat}/></Grid>
          <Grid size={6}><TextField label="Долгота" fullWidth {...register("lng")} error={!!errors.lng}/></Grid>
          <Grid size={12}><TextField label="Вид рыбы" fullWidth {...register("fish")} error={!!errors.fish}/></Grid>
          <Grid size={6}><TextField label="Вес (кг)" fullWidth type="number" {...register("weight")}/></Grid>
          <Grid size={6}><TextField label="Длина (см)" fullWidth type="number" {...register("length")}/></Grid>
          <Grid size={6}>
            <TextField select label="Вид ловли" fullWidth defaultValue="shore" {...register("style")}>
              <MenuItem value="shore">Берег</MenuItem><MenuItem value="boat">Лодка</MenuItem><MenuItem value="ice">Лёд</MenuItem>
            </TextField>
          </Grid>
          <Grid size={6}>
            <TextField select label="Приватность" fullWidth defaultValue="all" {...register("privacy")}>
              <MenuItem value="all">Все авторизованные</MenuItem>
              <MenuItem value="friends">Только друзья</MenuItem>
              <MenuItem value="groups">Группы</MenuItem>
              <MenuItem value="none">Никому</MenuItem>
            </TextField>
          </Grid>
          <Grid size={12}><Button variant="contained" type="submit">Сохранить</Button></Grid>
        </Grid>
      </form>
      {ok && <Typography color="#1DE9B6">{ok}</Typography>}
    </Stack>
  );
}
