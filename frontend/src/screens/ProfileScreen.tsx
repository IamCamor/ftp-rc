// src/screens/ProfileScreen.tsx
import React from "react";
import HeaderBar from "../components/HeaderBar";

export default function ProfileScreen() {
  return (
    <div className="w-full h-full">
      <HeaderBar title="Профиль" onWeather={() => (window.location.hash = "#/weather")} onProfile={() => {}} />
      <div className="mx-auto max-w-md px-3 mt-16 space-y-4 pb-24">
        <div className="glass p-4 flex items-center gap-3">
          <img src="/avatar.png" className="w-12 h-12 rounded-full object-cover" />
          <div>
            <div className="font-semibold">Рыбак</div>
            <div className="text-sm text-gray-600">@fisher</div>
          </div>
          <div className="ml-auto text-sm">Бонусы: <b>120</b></div>
        </div>
        <div className="glass p-4">
          <div className="font-medium mb-2">Мои действия</div>
          <ul className="list-disc list-inside text-sm text-gray-700 space-y-1">
            <li>Уловы, друзья, рейтинги — скоро</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
