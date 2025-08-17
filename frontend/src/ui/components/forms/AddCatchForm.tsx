import { useState } from "react";
import { Grid, TextField, Button, Stack, Alert, MenuItem, Typography, Card, CardContent } from "@mui/material";
import { getJson, postJson, upload } from "../../data/api";

export default function AddCatchForm(){
  const [f, setF] = useState<any>({
    lat: "", lng: "", species:"", length:"", weight:"", depth:"",
    style:"берег", lure:"", tackle:"", privacy:"all",
    companions:"", notes:"", caught_at:""
  });
  const [file, setFile] = useState<File|null>(null);
  const [msg, setMsg] = useState<string|null>(null); const [err,setErr]=useState<string|null>(null);
  const [weather,setWeather]=useState<any|null>(null);

  const onChange = (e: any) => setF({ ...f, [e.target.name]: e.target.value });
  const locate = () => {
    if (!navigator.geolocation) { setF({...f, lat:55.751244, lng:37.618423}); return; }
    navigator.geolocation.getCurrentPosition(pos => setF({...f, lat:pos.coords.latitude, lng:pos.coords.longitude}));
  };
  const previewWeather = async () => {
    try { setWeather(await getJson("/weather", { lat: f.lat, lng: f.lng, units:"metric", lang:"ru" })); } catch {}
  };
  const submit = async () => {
    setMsg(null); setErr(null);
    try {
      const rec = await postJson("/catches", f);
      if (file) await upload(`/catches/${rec.id}/media`, file);
      setMsg("Улов сохранён");
    } catch(e:any){ setErr(e.message); }
  };
  return (
    <Card variant="outlined"><CardContent>
      <Stack spacing={2}>
        <Stack direction="row" spacing={1}>
          <Button onClick={locate}>GPS</Button>
          <Button onClick={previewWeather}>Погода</Button>
        </Stack>
        {weather && <Alert severity="info">Темп: {weather.current?.temp ?? "—"}</Alert>}
        {msg && <Alert severity="success">{msg}</Alert>}
        {err && <Alert severity="error">{err}</Alert>}
        <Grid container spacing={2}>
          <Grid item xs={6}><TextField label="Широта" name="lat" value={f.lat} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={6}><TextField label="Долгота" name="lng" value={f.lng} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={6}><TextField label="Вид рыбы" name="species" value={f.species} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={3}><TextField label="Длина (см)" name="length" value={f.length} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={3}><TextField label="Вес (кг)" name="weight" value={f.weight} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={4}><TextField label="Глубина (м)" name="depth" value={f.depth} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={4}>
            <TextField label="Тип ловли" name="style" value={f.style} onChange={onChange} select fullWidth>
              <MenuItem value="берег">Берег</MenuItem>
              <MenuItem value="лодка">Лодка</MenuItem>
              <MenuItem value="лёд">Лёд</MenuItem>
            </TextField>
          </Grid>
          <Grid item xs={4}><TextField label="Приманка" name="lure" value={f.lure} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={6}><TextField label="Снасти" name="tackle" value={f.tackle} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={6}>
            <TextField label="Приватность" name="privacy" value={f.privacy} onChange={onChange} select fullWidth>
              <MenuItem value="all">Все авторизованные</MenuItem>
              <MenuItem value="friends">Только друзья</MenuItem>
              <MenuItem value="groups">Группы</MenuItem>
              <MenuItem value="none">Никому</MenuItem>
            </TextField>
          </Grid>
          <Grid item xs={12}><TextField label="С кем" name="companions" value={f.companions} onChange={onChange} fullWidth/></Grid>
          <Grid item xs={12}><TextField label="Заметки" name="notes" value={f.notes} onChange={onChange} fullWidth multiline minRows={3}/></Grid>
          <Grid item xs={6}><TextField label="Дата/время" name="caught_at" value={f.caught_at} onChange={onChange} fullWidth placeholder="YYYY-MM-DD HH:mm"/></Grid>
          <Grid item xs={12}><Button variant="outlined" component="label">Фото<input type="file" hidden accept="image/*" onChange={e=>setFile(e.target.files?.[0]||null)} /></Button></Grid>
          {file && <Grid item xs={12}><Typography variant="body2">Файл: {file.name}</Typography></Grid>}
          <Grid item xs={12}><Button variant="contained" onClick={submit}>Сохранить</Button></Grid>
        </Grid>
      </Stack>
    </CardContent></Card>
  );
}
