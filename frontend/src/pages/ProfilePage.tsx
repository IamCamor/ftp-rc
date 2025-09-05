import React from "react";
import Avatar from "../components/Avatar";
import Icon from "../components/Icon";
import { API } from "../api";
import { Link } from "react-router-dom";

export default function ProfilePage(){
  const [me,setMe]=React.useState<any>(null);
  const [loading,setLoading]=React.useState(true);

  React.useEffect(()=>{
    (async()=>{
      try{
        const data = await API.profile();
        setMe(data);
      }catch(e){ console.warn(e); setMe(null); }
      finally{ setLoading(false); }
    })();
  },[]);

  if(loading) return <div className="page"><div className="loader">Загрузка…</div></div>;

  return (
    <div className="page profile-page">
      <div className="card prof-card">
        <div className="prof-row">
          <Avatar src={me?.avatar || me?.photo_url} size={64}/>
          <div className="flex-col">
            <h2>{me?.name || "Гость"}</h2>
            <div className="muted">Уловов: {me?.stats?.catches ?? "—"} · Друзья: {me?.stats?.friends ?? "—"}</div>
          </div>
          <div className="grow"></div>
          <Link to="/ratings" className="btn ghost"><Icon name="rating"/> Рейтинги</Link>
        </div>
        <div className="grid two mt">
          <Link to="/friends" className="btn"><Icon name="friends"/> Друзья</Link>
          <a href="/logout" className="btn"><Icon name="logout"/> Выход</a>
        </div>
      </div>

      <div className="card">
        <div className="card-h"><b>Мои уловы</b></div>
        <div className="muted small">Будет список с пагинацией и быстрым переходом на карту.</div>
      </div>
    </div>
  );
}
