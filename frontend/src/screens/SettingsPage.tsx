import React from "react";
import Icon from "../components/Icon";

export default function SettingsPage(){
  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="settings"/><div className="font-semibold">Настройки</div>
      </div>
      <div className="p-4 space-y-3">
        <a className="block p-3 rounded-xl bg-white/70 border border-white/50" href="/agreements">Пользовательское соглашение</a>
        <a className="block p-3 rounded-xl bg-white/70 border border-white/50" href="/privacy">Политика конфиденциальности</a>
        <a className="block p-3 rounded-xl bg-white/70 border border-white/50" href="/logout">Выйти</a>
      </div>
    </div>
  );
}
