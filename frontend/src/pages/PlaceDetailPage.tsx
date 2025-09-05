import React from "react";
import { useParams, Link } from "react-router-dom";
import { API } from "../api";
import Icon from "../components/Icon";
import MediaGrid from "../components/MediaGrid";

export default function PlaceDetailPage(){
  const { id } = useParams();
  const [place, setPlace] = React.useState<any>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(()=>{
    let stopped=false;
    (async()=>{
      try{
        // На бэке show для точки: GET /map/points/{id}
        const data = await fetch(`${location.protocol}//${location.host.includes("www.")? "www.":""}${location.host}/api/v1/map/points/${id}`, { credentials:"include" })
          .then(r=>r.ok?r.json():Promise.reject(r.status));
        if(!stopped) setPlace(data);
      }catch(e){ console.warn(e); if(!stopped) setPlace(null);}
      finally{ if(!stopped) setLoading(false); }
    })();
    return ()=>{stopped=true};
  },[id]);

  if(loading) return <div className="page"><div className="loader">Загрузка…</div></div>;
  if(!place) return <div className="page"><div className="empty">Точка не найдена</div></div>;

  return (
    <div className="page place-page">
      <div className="page-title">
        <Link to="/map" className="icon-btn"><Icon name="back"/></Link>
        <h1>{place.name || "Точка"}</h1>
      </div>

      {place.description && <p className="muted">{place.description}</p>}

      {place.photos?.length ? (
        <MediaGrid items={place.photos.map((url:string)=>({url}))}/>
      ) : (
        <div className="empty small">Фотографий нет</div>
      )}

      <div className="block">
        <div><Icon name="place"/> <b>Координаты:</b> {place.lat}, {place.lng}</div>
        {place.type && <div><b>Тип:</b> {place.type}</div>}
      </div>

      <div className="page-actions">
        <Link className="btn" to={`/map?lat=${place.lat}&lng=${place.lng}&z=14`}><Icon name="map"/> Открыть на карте</Link>
      </div>
    </div>
  );
}
