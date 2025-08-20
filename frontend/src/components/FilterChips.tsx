import React from "react";
export const FILTERS = ["Все","Споты","Магазины","Слипы","Кемпинги","Уловы"] as const;
export type FilterName = typeof FILTERS[number];
export default function FilterChips({active,onChange}:{active:FilterName; onChange:(f:FilterName)=>void}) {
  return (
    <div className="fixed top-16 left-0 w-full px-3 z-[1190]">
      <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
        {FILTERS.map((f)=> {
          const is = active===f;
          return (
            <button key={f} onClick={()=>onChange(f)}
              className={"px-4 py-2 rounded-xl text-sm whitespace-nowrap "+(is? "text-white shadow grad-ig":"glass text-gray-700")}>
              {f}
            </button>
          );
        })}
      </div>
    </div>
  );
}
