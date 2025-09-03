// src/components/HeaderBar.tsx
import React from "react";
import Icon from "./Icon";

export default function HeaderBar({
  title,
  onWeather,
  onProfile,
}: {
  title: string;
  onWeather?: () => void;
  onProfile?: () => void;
}) {
  return (
    <div className="fixed top-0 left-0 right-0 z-30">
      <div className="mx-auto max-w-md px-3 pt-4">
        <div className="glass flex items-center justify-between h-12 px-3">
          <div className="flex items-center gap-2">
            <img src="/logo.svg" alt="logo" className="w-6 h-6" />
            <div className="font-semibold">{title}</div>
          </div>
          <div className="flex items-center gap-3">
            <button className="text-gray-600" onClick={onWeather} aria-label="Погода">
              <Icon name="weather" className="w-6 h-6" />
            </button>
            <button className="w-8 h-8 rounded-full overflow-hidden ring-1 ring-white/70" onClick={onProfile}>
              <img src="/avatar.png" alt="me" className="w-full h-full object-cover" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
