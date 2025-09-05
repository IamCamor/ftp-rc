import React from "react";
import { useNavigate } from "react-router-dom";

export default function PointPinCard({point}:{point:any}) {
  const nav = useNavigate();
  const go = ()=> nav(`/place/${point.id}`);
  return (
    <div className="pin-card" onClick={go}>
      <div className="pin-title"><strong>{point.name||"Точка"}</strong> <small>{point.type||""}</small></div>
      {point.photos?.[0] && <img src={point.photos[0]} alt={point.name} className="pin-photo" />}
      <div className="pin-link">Открыть точку →</div>
    </div>
  )
}
