import React from 'react';

export default function Header({ onLogoClick }:{ onLogoClick?:()=>void }) {
  return (
    <div className="fixed top-0 left-0 right-0 z-40">
      <div className="mx-auto max-w-screen-sm px-4 pt-3">
        <div className="backdrop-blur-xl bg-white/60 border border-white/40 rounded-2xl shadow-sm px-3 py-2 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <button onClick={onLogoClick} className="font-semibold text-gray-900">FishTrack Pro</button>
            <span className="text-xs px-2 py-1 rounded-full bg-gradient-to-r from-pink-400 to-fuchsia-500 text-white">beta</span>
          </div>
          <div className="flex items-center gap-4">
            <button
              className="text-sm text-gray-700 hover:text-gray-900"
              onClick={() => { window.location.hash = '#/weather'; }}
              aria-label="Открыть погоду"
              title="Погода"
            >
              ☁️ Погода
            </button>
            <button
              className="text-sm text-gray-700 hover:text-gray-900"
              onClick={() => { window.location.hash = '#/alerts'; }}
              aria-label="Уведомления"
              title="Уведомления"
            >
              🔔
            </button>
            <button
              className="text-sm text-gray-700 hover:text-gray-900"
              onClick={() => { window.location.hash = '#/profile'; }}
              aria-label="Профиль"
              title="Профиль"
            >
              🧑‍✈️
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
