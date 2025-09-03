// src/components/FilterChips.tsx
import React from "react";

const FILTERS = [
  { id: "all", label: "Все" },
  { id: "spot", label: "Споты" },
  { id: "shop", label: "Магазины" },
  { id: "slip", label: "Слипы" },
  { id: "camp", label: "Кемпинги" },
  { id: "catch", label: "Уловы" },
];

export default function FilterChips({
  active,
  onChange,
}: {
  active: string;
  onChange: (id: string) => void;
}) {
  return (
    <div className="mx-auto max-w-md px-3 mt-16">
      <div className="glass overflow-x-auto no-scrollbar flex gap-2 p-2">
        {FILTERS.map((f) => {
          const is = active === f.id;
          return (
            <button
              key={f.id}
              onClick={() => onChange(f.id)}
              className={`px-3 py-1.5 rounded-full border ${
                is ? "bg-pink-500 text-white border-pink-400" : "bg-white/40 text-gray-700 border-white/60"
              }`}
            >
              {f.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
