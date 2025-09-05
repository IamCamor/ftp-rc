import React from "react";
import { CONFIG } from "../config";
export default function Avatar({src,size=36}:{src?:string,size?:number}) {
  const [err,setErr]=React.useState(false);
  const url = !err && src ? src : CONFIG.images.avatarDefault;
  return <img className="avatar" style={{width:size,height:size}} src={url} onError={()=>setErr(true)} alt="avatar"/>;
}
