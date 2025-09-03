// src/screens/WeatherPage.tsx
import React, { useEffect, useState } from "react";
import HeaderBar from "../components/HeaderBar";
import { api } from "../api";

type SavedLoc = { name: string; lat: number; lng: number };

const LOCAL_KEY = "weather_locs_v1";

export default function WeatherPage() {
  const [locs, setLocs] = useState<SavedLoc[]>(() => {
    try { return JSON.parse(localStorage.getItem(LOCAL_KEY) || "[]"); } catch { return []; }
  });
  const [wx, setWx] = useState<Record<string, any>>({});

  useEffect(() => {
    locs.forEach(async (l) => {
      const k = `${l.lat.toFixed(3)},${l.lng.toFixed(3)}`;
      const data = await api.weather(l.lat, l.lng).catch(() => ({}));
      setWx((x) => ({ ...x, [k]: data }));
    });
  }, [locs]);

  const addCurrent = () => {
    navigator.geolocation.getCurrentPosition((pos) => {
      const l = { name: "Текущее", lat: pos.coords.latitude, lng: pos.coords.longitude };
      const next = [...locs, l];
      setLocs(next); localStorage.setItem(LOCAL_KEY, JSON.stringify(next));
    });
  };

  return (
    <div className="w-full h-full">
      <HeaderBar title="Погода" />
      <div className="mx-auto max-w-md px-3 mt-16 space-y-3 pb-24">
        <div className="glass p-3 flex items-center justify-between">
          <div className="font-medium">Локации</div>
          <button className="text-pink-500" onClick={addCurrent}>+ добавить текущую</button>
        </div>
        {locs.map((l) => {
          const k = `${l.lat.toFixed(3)},${l.lng.toFixed(3)}`;
          const d = wx[k] || {};
          const temp = d?.current?.temp ?? d?.temp ?? "—";
          const wind = d?.current?.wind_speed ?? d?.wind_speed ?? "—";
          return (
            <div key={k} className="glass p-4">
              <div className="flex items-center justify-between">
                <div className="font-semibold">{l.name}</div>
                <div className="text-sm text-gray-600">{l.lat.toFixed(3)}, {l.lng.toFixed(3)}</div>
              </div>
              <div className="mt-2 text-sm text-gray-700">Температура: <b>{temp}</b>, Ветер: <b>{wind}</b></div>
            </div>
          );
        })}
        {locs.length === 0 && <div className="text-center text-gray-500 mt-6">Добавьте локацию</div>}
      </div>
    </div>
  );
}
