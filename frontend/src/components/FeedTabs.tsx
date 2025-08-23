import React from "react";

type Tab = "global"|"local"|"follow";
const TABS: {key: Tab; label: string}[] = [
  {key:"global", label:"Глобально"},
  {key:"local",  label:"Рядом"},
  {key:"follow", label:"Подписки"},
];

export default function FeedTabs({active, onChange}:{active:Tab; onChange:(t:Tab)=>void}) {
  return (
    <div className="flex gap-2 p-2 rounded-2xl bg-white/60 backdrop-blur border border-white/60 sticky top-0 z-20">
      {TABS.map(t => {
        const is = active===t.key;
        return (
          <button
            key={t.key}
            onClick={()=>onChange(t.key)}
            className={
              "px-3 py-1 rounded-full text-sm " +
              (is ? "bg-white border border-white shadow font-semibold" : "bg-transparent border border-transparent text-gray-600")
            }
            aria-pressed={is}
          >
            {t.label}
          </button>
        );
      })}
    </div>
  );
}
