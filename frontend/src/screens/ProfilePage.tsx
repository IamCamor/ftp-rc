import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";
import { ASSETS } from "../config/ui";

type Profile = {
  id: number;
  name: string;
  handle?: string;
  avatar?: string;
  bonus?: number;
  catches_count?: number;
  friends_count?: number;
  followers_count?: number;
};

async function fetchMe(): Promise<Profile | null> {
  try {
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/profile/me`, { credentials: "include" });
    if (!r.ok) return null;
    const j = await r.json();
    return j?.data || j || null;
  } catch {
    return null;
  }
}

export default function ProfilePage(){
  const [me, setMe] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(()=> {
    fetchMe().then((p)=> { setMe(p); setLoading(false); });
  },[]);

  const avatar = me?.avatar || ASSETS.defaultAvatar;

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <img src={ASSETS.logo} alt="logo" className="w-6 h-6" />
          <div className="font-semibold">Профиль</div>
        </div>
        <a href="#/weather" className="flex items-center gap-1 text-sm">
          <Icon name="weather" /> Погода
        </a>
      </div>

      {loading ? (
        <div className="p-4 text-gray-500">Загрузка…</div>
      ) : me ? (
        <>
          <div className="p-4 flex items-center gap-3">
            <img src={avatar} alt="" className="w-16 h-16 rounded-full object-cover border border-white/40 shadow" />
            <div className="flex-1">
              <div className="font-semibold text-lg">{me.name}</div>
              <div className="text-gray-500 text-sm">@{me.handle || "user" + me.id}</div>
              <div className="mt-1 text-sm">
                <span className="inline-flex items-center gap-1 mr-3"><Icon name="rating" /> {me.bonus ?? 0}</span>
                <span className="inline-flex items-center gap-1 mr-3"><Icon name="place" /> {me.catches_count ?? 0}</span>
                <span className="inline-flex items-center gap-1"><Icon name="friends" /> {me.friends_count ?? 0}</span>
              </div>
            </div>
            <a href="#/settings" className="btn text-sm inline-flex items-center gap-1"><Icon name="settings" /> Настройки</a>
          </div>

          <div className="px-4 grid grid-cols-2 gap-3">
            <a href="#/my-catches" className="p-3 rounded-2xl bg-white/60 backdrop-blur border border-white/50 shadow-sm flex items-center gap-2">
              <Icon name="photo" /> Мои уловы
            </a>
            <a href="#/friends" className="p-3 rounded-2xl bg-white/60 backdrop-blur border border-white/50 shadow-sm flex items-center gap-2">
              <Icon name="friends" /> Друзья
            </a>
            <a href="#/ratings" className="p-3 rounded-2xl bg-white/60 backdrop-blur border border-white/50 shadow-sm flex items-center gap-2">
              <Icon name="rating" /> Рейтинги
            </a>
            <a href="#/logout" className="p-3 rounded-2xl bg-white/60 backdrop-blur border border-white/50 shadow-sm flex items-center gap-2">
              <Icon name="logout" /> Выйти
            </a>
          </div>
        </>
      ) : (
        <div className="p-4">
          <div className="rounded-2xl p-4 bg-white/60 backdrop-blur border border-white/50">
            <div className="font-semibold mb-1">Требуется вход</div>
            <div className="text-sm text-gray-600 mb-3">Войдите, чтобы видеть профиль и бонусы.</div>
            <a href="#/auth" className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-black text-white">
              <Icon name="login" /> Войти
            </a>
          </div>
        </div>
      )}
    </div>
  );
}
