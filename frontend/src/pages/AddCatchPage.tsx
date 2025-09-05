import React from "react";
import Icon from "../components/Icon";
import { API } from "../api";

export default function AddCatchPage(){
  const [form, setForm] = React.useState<any>({
    lat: "", lng: "", species:"", length:"", weight:"",
    style:"", lure:"", tackle:"", notes:"", privacy:"all",
    caught_at:""
  });
  const [media, setMedia] = React.useState<File[]>([]);
  const [loading, setLoading] = React.useState(false);
  const [wx, setWx] = React.useState<any>(null);

  const onChange=(e:React.ChangeEvent<HTMLInputElement|HTMLTextAreaElement|HTMLSelectElement>)=>{
    const {name,value} = e.target;
    setForm((s:any)=>({...s,[name]:value}));
  };

  const pickMedia=(e:React.ChangeEvent<HTMLInputElement>)=>{
    const files = Array.from(e.target.files||[]);
    setMedia(files);
  };

  const fetchWx = async ()=>{
    const lat = Number(form.lat), lng = Number(form.lng);
    if(Number.isNaN(lat) || Number.isNaN(lng)) return;
    try{
      const dt = form.caught_at ? Math.floor(new Date(form.caught_at).getTime()/1000) : undefined;
      const data = await API.weather(lat, lng, dt);
      setWx(data);
    }catch(e){ console.warn(e); }
  };

  const submit = async (e:React.FormEvent)=>{
    e.preventDefault();
    try{
      setLoading(true);

      // загрузка медиа по одному (если есть /upload)
      const mediaUrls:string[]=[];
      for(const f of media){
        const fd = new FormData();
        fd.append("file", f);
        const res = await fetch(`${(window as any).API_BASE||""}/upload`, { // если прокинут глобально
          method:"POST", body:fd, credentials:"include"
        }).then(r=>r.ok?r.json():Promise.reject(r.status)).catch(()=>null);
        if(res?.url) mediaUrls.push(res.url);
      }

      const payload = {
        ...form,
        lat: Number(form.lat), lng: Number(form.lng),
        photo_url: mediaUrls[0] || "",
        media_urls: mediaUrls,
        // нормализуем дату для MySQL DATETIME
        ...(form.caught_at ? { caught_at: new Date(form.caught_at).toISOString().slice(0,19).replace('T',' ') } : {}),
        // погода (не блокирующая)
        weather: wx || undefined
      };

      const ok = await API.addCatch(payload);
      alert("Улов отправлен на модерацию / сохранён");
      console.log(ok);
    }catch(e:any){
      alert("Ошибка отправки: "+(e?.message||e));
    }finally{ setLoading(false); }
  };

  return (
    <div className="page addcatch-page">
      <div className="page-title">
        <Icon name="addPhoto" size={22}/> <h1>Добавить улов</h1>
      </div>

      <form className="form" onSubmit={submit}>
        <div className="grid">
          <label>Координаты (lat)
            <input name="lat" value={form.lat} onChange={onChange} placeholder="55.75" onBlur={fetchWx}/>
          </label>
          <label>Координаты (lng)
            <input name="lng" value={form.lng} onChange={onChange} placeholder="37.62" onBlur={fetchWx}/>
          </label>
          <label>Дата/время поимки
            <input type="datetime-local" name="caught_at" value={form.caught_at} onChange={onChange} onBlur={fetchWx}/>
          </label>
          <label>Вид рыбы
            <input name="species" value={form.species} onChange={onChange} placeholder="Щука"/>
          </label>
          <label>Длина (см)
            <input name="length" value={form.length} onChange={onChange} placeholder="60"/>
          </label>
          <label>Вес (кг)
            <input name="weight" value={form.weight} onChange={onChange} placeholder="2.4"/>
          </label>
          <label>Стиль ловли
            <select name="style" value={form.style} onChange={onChange}>
              <option value="">—</option>
              <option value="spinning">Спиннинг</option>
              <option value="float">Поплавок</option>
              <option value="feeder">Фидер</option>
              <option value="fly">Нахлыст</option>
            </select>
          </label>
          <label>Приманка
            <input name="lure" value={form.lure} onChange={onChange} placeholder="Воблер"/>
          </label>
          <label>Оснастка
            <input name="tackle" value={form.tackle} onChange={onChange} placeholder="Шнур 0.12, поводок…"/>
          </label>
          <label>Приватность
            <select name="privacy" value={form.privacy} onChange={onChange}>
              <option value="all">Публично</option>
              <option value="friends">Для друзей</option>
              <option value="private">Только я</option>
            </select>
          </label>
          <label className="full">Заметки
            <textarea name="notes" value={form.notes} onChange={onChange} placeholder="Где, когда, что сработало…"/>
          </label>
          <label className="full">Фото/видео
            <input type="file" accept="image/*,video/*" multiple onChange={pickMedia}/>
          </label>
        </div>

        <div className="wx-preview">
          <div className="muted">Погода (автоподстановка):</div>
          <pre>{wx ? JSON.stringify(wx, null, 2) : "—"}</pre>
        </div>

        <div className="form-actions">
          <button type="submit" className="btn primary" disabled={loading}>
            <Icon name="save"/> {loading?"Сохранение…":"Сохранить улов"}
          </button>
        </div>
      </form>
    </div>
  );
}
