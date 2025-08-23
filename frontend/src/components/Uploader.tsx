import React, { useRef, useState } from "react";
import { apiUpload } from "../lib/api";
import { Button } from "./ui";
import { toast } from "../lib/toast";

export default function Uploader({onUploaded}:{onUploaded:(url:string,type:'image'|'video')=>void}){
  const inputRef = useRef<HTMLInputElement>(null);
  const [loading,setLoading] = useState(false);

  const onPick = ()=> inputRef.current?.click();

  const onChange = async (e: React.ChangeEvent<HTMLInputElement>)=>{
    const f = e.target.files?.[0]; if(!f) return;
    setLoading(true);
    try {
      const res = await apiUpload(f);
      onUploaded(res.url, res.type);
      toast("Файл загружен");
    } catch(e:any){
      toast("Ошибка загрузки");
      console.error(e);
    } finally {
      setLoading(false);
      e.target.value = "";
    }
  }

  return (
    <div className="flex items-center gap-3">
      <input ref={inputRef} type="file" accept="image/*,video/*" className="hidden" onChange={onChange}/>
      <Button onClick={onPick} variant="secondary">{loading ? "Загрузка…" : "Загрузить фото/видео"}</Button>
    </div>
  );
}
