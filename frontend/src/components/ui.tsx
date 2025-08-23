import React from "react";
export const Card = ({children,className=""}:{children:any;className?:string}) =>
  <div className={"rounded-2xl bg-white/70 backdrop-blur border border-white/60 shadow-md "+className}>{children}</div>;
export const CardContent = ({children,className=""}:{children:any;className?:string}) =>
  <div className={"p-4 "+className}>{children}</div>;
export const Button = ({children,onClick,type="button",variant="default",className=""}:{children:any;onClick?:any;type?:"button"|"submit";variant?:"default"|"secondary"|"ghost";className?:string;})=>{
  const map:any={default:"bg-black text-white",secondary:"bg-white/70 border border-white/60",ghost:"bg-transparent"};
  return <button type={type} onClick={onClick} className={`rounded-full px-4 py-2 ${map[variant]} ${className}`}>{children}</button>;
};
export const Input = (p:React.InputHTMLAttributes<HTMLInputElement>) =>
  <input {...p} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+(p.className||"")} />;
export const Textarea = (p:React.TextareaHTMLAttributes<HTMLTextAreaElement>) =>
  <textarea {...p} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+(p.className||"")} />;
export const Select = ({value,onChange,children,className=""}:{value:any;onChange:any;children:any;className?:string}) =>
  <select value={value} onChange={onChange} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+className}>{children}</select>;
