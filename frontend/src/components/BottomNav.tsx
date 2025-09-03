// src/components/BottomNav.tsx
import React from "react";
import Icon from "./Icon";

type Tab = "map" | "feed" | "alerts" | "profile";

export default function BottomNav({
  active,
  onChange,
  onFab,
}: {
  active: Tab;
  onChange: (t: Tab) => void;
  onFab: () => void;
}) {
  const Item = ({
    id,
    icon,
    label,
  }: {
    id: Tab;
    icon: string;
    label: string;
  }) => (
    <button
      onClick={() => onChange(id)}
      className={`flex flex-col items-center justify-center px-4 pt-2 pb-1 text-xs ${
        active === id ? "text-pink-500" : "text-gray-500"
      }`}
    >
      <Icon name={icon} className="w-6 h-6" />
      <div className="mt-1">{label}</div>
    </button>
  );

  return (
    <div className="fixed bottom-0 left-0 right-0 z-40">
      <div className="mx-auto max-w-md">
        <div className="relative glass flex items-center justify-between h-16 mx-3 mb-3 px-2">
          <Item id="map" icon="map" label="Карта" />
          <Item id="feed" icon="feed" label="Лента" />

          {/* FAB centered */}
          <button
            aria-label="Добавить"
            onClick={onFab}
            className="absolute -top-6 left-1/2 -translate-x-1/2 bg-gradient-to-r from-pink-400 to-purple-500 text-white rounded-full shadow-xl w-14 h-14 flex items-center justify-center ring-4 ring-white"
          >
            <Icon name="plus" className="w-7 h-7" />
          </button>

          <Item id="alerts" icon="bell" label="Оповещения" />
          <Item id="profile" icon="user" label="Профиль" />
        </div>
      </div>
    </div>
  );
}
