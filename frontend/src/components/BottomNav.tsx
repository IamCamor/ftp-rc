import React from "react";
import { asString, safeSlice } from "../lib/safe"; // путь поправь под свой алиас/структуру

type Tab = "map" | "feed" | "alerts" | "profile";

type BottomNavProps = {
  active: Tab;
  onChange: (t: Tab) => void;
  onFab: () => void;
  // необязательный бейдж у вкладок, например {feed: 3}
  badges?: Partial<Record<Tab, number | string>>;
  // подписи можно переопределить, если понадобится локализация
  labels?: Partial<Record<Tab, string>>;
};

const DEFAULT_LABELS: Record<Tab, string> = {
  map: "Карта",
  feed: "Лента",
  alerts: "Уведомл.",
  profile: "Профиль",
};

// Простейшие иконки (SVG) в тонком стиле; можно заменить на из набора
const IconMap = ({ active }: { active: boolean }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden>
    <path
      d="M3 6l6-2 6 2 6-2v14l-6 2-6-2-6 2V6zM9 4v14M15 6v14"
      fill="none"
      stroke={active ? "currentColor" : "currentColor"}
      strokeOpacity={active ? 1 : 0.6}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);
const IconFeed = ({ active }: { active: boolean }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden>
    <path
      d="M4 6h16M4 12h16M4 18h10"
      fill="none"
      stroke={active ? "currentColor" : "currentColor"}
      strokeOpacity={active ? 1 : 0.6}
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);
const IconBell = ({ active }: { active: boolean }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden>
    <path
      d="M15 18H9m8-2V11a5 5 0 10-10 0v5l-2 2h14l-2-2zM12 22a2 2 0 002-2H10a2 2 0 002 2z"
      fill="none"
      stroke={active ? "currentColor" : "currentColor"}
      strokeOpacity={active ? 1 : 0.6}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);
const IconUser = ({ active }: { active: boolean }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden>
    <path
      d="M12 12a5 5 0 100-10 5 5 0 000 10zm8 10v-1a7 7 0 00-14 0v1"
      fill="none"
      stroke={active ? "currentColor" : "currentColor"}
      strokeOpacity={active ? 1 : 0.6}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

export default function BottomNav({
  active,
  onChange,
  onFab,
  badges = {},
  labels = {},
}: BottomNavProps) {
  // собираем подписи безопасно, без прямых .slice
  const L = {
    map: asString(labels.map ?? DEFAULT_LABELS.map),
    feed: asString(labels.feed ?? DEFAULT_LABELS.feed),
    alerts: asString(labels.alerts ?? DEFAULT_LABELS.alerts),
    profile: asString(labels.profile ?? DEFAULT_LABELS.profile),
  };

  // ограничим подписи, если где-то придёт слишком длинно
  const label = (t: Tab) => safeSlice(L[t], 10); // безопасная обрезка строки

  const Button = ({
    tab,
    children,
  }: {
    tab: Tab;
    children: React.ReactNode;
  }) => {
    const isActive = active === tab;
    const badgeVal = badges[tab];
    return (
      <button
        type="button"
        onClick={() => onChange(tab)}
        className={[
          "relative flex flex-col items-center justify-center gap-1 px-3 py-2 rounded-2xl",
          "text-xs transition-all select-none",
          isActive
            ? "text-gray-900 font-medium"
            : "text-gray-700/70 hover:text-gray-900",
        ].join(" ")}
        aria-current={isActive ? "page" : undefined}
      >
        {/* иконка */}
        <div
          className={[
            "w-10 h-10 grid place-items-center rounded-2xl",
            isActive
              ? "bg-white/40 shadow-sm"
              : "bg-white/20 hover:bg-white/30",
            "backdrop-blur-md border border-white/30",
          ].join(" ")}
        >
          {children}
        </div>

        {/* подпись */}
        <div className="min-h-[1rem]">
          <span className="whitespace-nowrap">{label(tab)}</span>
        </div>

        {/* бейдж, если есть */}
        {badgeVal !== undefined && badgeVal !== null && (
          <span
            className="absolute -top-1 right-4 text-[10px] px-1.5 py-0.5 rounded-full
                       bg-pink-500/80 text-white border border-white/40"
            aria-label={`новые: ${badgeVal}`}
          >
            {asString(badgeVal)}
          </span>
        )}
      </button>
    );
  };

  return (
    <div
      className="fixed bottom-4 left-1/2 -translate-x-1/2 z-[60]
                 w-[min(480px,94vw)]"
      role="navigation"
      aria-label="Нижняя навигация"
    >
      {/* контейнер с глассморфизмом */}
      <div
        className="relative w-full px-3 py-2 border shadow-lg rounded-3xl bg-white/30 backdrop-blur-xl border-white/40"
      >
        <div className="flex items-center justify-between">
          <Button tab="map">
            <IconMap active={active === "map"} />
          </Button>

          {/* FAB по центру */}
          <button
            type="button"
            onClick={onFab}
            className="relative grid w-16 h-16 -mt-8 text-white transition rounded-full shadow-xl place-items-center bg-gradient-to-br from-pink-400 to-teal-400 hover:scale-105 active:scale-95"
            aria-label="Добавить"
          >
            <svg width="26" height="26" viewBox="0 0 24 24" aria-hidden>
              <path
                d="M12 5v14M5 12h14"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
              />
            </svg>
          </button>

          <Button tab="feed">
            <IconFeed active={active === "feed"} />
          </Button>

          <Button tab="alerts">
            <IconBell active={active === "alerts"} />
          </Button>

          <Button tab="profile">
            <IconUser active={active === "profile"} />
          </Button>
        </div>
      </div>
    </div>
  );
}