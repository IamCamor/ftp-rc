import React from "react";
type Props = { value: string; onChange: (v: string) => void; };
export default function SearchBar({ value, onChange }: Props) {
  return (
    <div className="ui-top fixed top-4 left-1/2 -translate-x-1/2 w-[92%] z-30">
      <div className="glass rounded-2xl px-4 py-2 flex items-center">
        <span className="mr-2">🔍</span>
        <input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Поиск мест…"
          className="bg-transparent outline-none text-sm w-full text-gray-800 placeholder:text-gray-500"
        />
      </div>
    </div>
  );
}
