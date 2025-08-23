import React from "react";

export default function Modal({open, onClose, children, title}:{open:boolean; onClose:()=>void; title?:string; children:React.ReactNode}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50">
      <div className="absolute inset-0 bg-black/40" onClick={onClose}/>
      <div className="absolute left-1/2 top-10 -translate-x-1/2 w-[min(640px,95vw)] rounded-2xl bg-white/80 backdrop-blur border border-white/60 shadow-xl p-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold">{title ?? "Форма"}</h3>
          <button className="px-2 py-1 text-gray-500 hover:text-black" onClick={onClose}>✕</button>
        </div>
        <div className="mt-2">{children}</div>
      </div>
    </div>
  );
}
