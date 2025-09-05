import React from "react";
import Icon from "../components/Icon";
import { API } from "../api";
import dayjs from "dayjs";

type N = { id:number; title:string; body?:string; created_at?:string; read?:boolean; link?:string };

export default function NotificationsPage(){
  const [list,setList]=React.useState<N[]>([]);
  const [loading,setLoading]=React.useState(true);

  React.useEffect(()=>{
    (async()=>{
      try{
        const data:any = await API.notifications();
        const items: N[] = Array.isArray(data)?data:(Array.isArray(data?.items)?data.items:[]);
        setList(items);
      }catch(e){ console.warn(e); setList([]); }
      finally{ setLoading(false); }
    })();
  },[]);

  return (
    <div className="page alerts-page">
      <div className="page-title">
        <Icon name="alerts" size={22}/> <h1>Уведомления</h1>
      </div>
      {loading && <div className="loader">Загрузка…</div>}
      {!loading && !list.length && <div className="empty">Пока пусто</div>}

      <div className="cards">
        {list.map(n=>(
          <a key={n.id} className={"card notif"+(n.read?" read":"")} href={n.link||"#"} target={n.link?"_blank":"_self"} rel="noreferrer">
            <div className="card-h">
              <b>{n.title}</b>
              <span className="muted small">{n.created_at? dayjs(n.created_at).format("DD.MM HH:mm"):""}</span>
            </div>
            {n.body && <div className="card-b">{n.body}</div>}
          </a>
        ))}
      </div>
    </div>
  );
}
