import React from "react";
import cls from "classnames";
const FILTERS = ["Все","Споты","Магазины","Слипы","Кемпинги","Уловы"] as const;
export type FilterName = typeof FILTERS[number];
type Props = { active: FilterName; onChange: (f: FilterName) => void; };
export default function FilterChips({ active, onChange }: Props) {
  return (
    <div className="ui-top fixed top-16 left-0 w-full px-3 z-20">
      <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
        {FILTERS.map((f) => (
          <button
            key={f}
            onClick={() => onChange(f)}
            className={cls(
              "px-4 py-2 rounded-xl text-sm whitespace-nowrap",
              active===f ? "text-white shadow grad-ig" : "glass text-gray-700"
            )}
          >
            {f}
          </button>
        ))}
      </div>
    </div>
  );
}
