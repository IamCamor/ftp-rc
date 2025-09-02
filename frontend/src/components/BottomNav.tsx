
import React from "react";

type Item = { key: string; label: string; icon: "map"|"feed"|"weather"|"trophy"|"user" };
type Props<T extends string> = {
  items: Item[];
  active: T;
  onChange: (t: T)=>void;
  onFab: ()=>void;
};

const Icon = ({name}:{name:Item["icon"]}) => {
  // простые иконки на svg, чтобы не тянуть либы
  const common = "w-6 h-6";
  switch(name){
    case "map": return (<svg className={common} viewBox="0 0 24 24" fill="none"><path d="M3 6l6-2 6 2 6-2v14l-6 2-6-2-6 2V6z" stroke="currentColor" strokeWidth="1.5"/><circle cx="12" cy="10" r="2.5" stroke="currentColor" strokeWidth="1.5"/></svg>);
    case "feed": return (<svg className={common} viewBox="0 0 24 24" fill="none"><rect x="4" y="4" width="16" height="5" rx="1.5" stroke="currentColor" strokeWidth="1.5"/><rect x="4" y="11" width="10" height="9" rx="1.5" stroke="currentColor" strokeWidth="1.5"/></svg>);
    case "weather": return (<svg className={common} viewBox="0 0 24 24" fill="none"><path d="M7 17a4 4 0 010-8 5 5 0 119 3h1a3 3 0 010 6H7z" stroke="currentColor" strokeWidth="1.5"/></svg>);
    case "trophy": return (<svg className={common} viewBox="0 0 24 24" fill="none"><path d="M7 4h10v3a5 5 0 01-10 0V4zM5 7H3a4 4 0 004 4m12-4h2a4 4 0 01-4 4M9 21h6" stroke="currentColor" strokeWidth="1.5"/></svg>);
    case "user": return (<svg className={common} viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="3.5" stroke="currentColor" strokeWidth="1.5"/><path d="M5 20a7 7 0 0114 0" stroke="currentColor" strokeWidth="1.5"/></svg>);
  }
};

export default function BottomNav<T extends string>({items, active, onChange, onFab}:Props<T>){
  return (
    <div className="pointer-events-none fixed bottom-4 left-0 right-0 flex justify-center">
      <div className="pointer-events-auto relative flex items-center gap-6 px-4 py-2 rounded-2xl backdrop-blur-md bg-white/60 border border-white/40 shadow-lg">
        {items.slice(0,2).map(it=>(
          <button key={it.key} onClick={()=>onChange(it.key as T)}
            className={"px-2 py-1 rounded-md text-sm flex flex-col items-center "+(active===it.key?"text-pink-600":"text-gray-600")}
            aria-label={it.label}
          >
            <Icon name={it.icon}/><span className="text-[11px] mt-1">{it.label}</span>
          </button>
        ))}
        {/* FAB центр */}
        <button onClick={onFab} aria-label="Добавить" className="-mt-8 w-14 h-14 rounded-full bg-gradient-to-tr from-pink-500 to-fuchsia-500 text-white shadow-xl flex items-center justify-center border border-white/40">
          <svg className="w-7 h-7" viewBox="0 0 24 24" fill="none"><path d="M12 5v14M5 12h14" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/></svg>
        </button>
        {items.slice(2).map(it=>(
          <button key={it.key} onClick={()=>onChange(it.key as T)}
            className={"px-2 py-1 rounded-md text-sm flex flex-col items-center "+(active===it.key?"text-pink-600":"text-gray-600")}
            aria-label={it.label}
          >
            <Icon name={it.icon}/><span className="text-[11px] mt-1">{it.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
