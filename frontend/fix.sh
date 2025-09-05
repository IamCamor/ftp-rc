#!/usr/bin/env bash
set -euo pipefail

ROOT="src/config"
FILE="$ROOT/ui.ts"

mkdir -p "$ROOT"

cat > "$FILE" <<'TS'
// UI-конфиги и ассеты приложения (только конфиг, без кода UI)
// ВАЖНО: именованный экспорт ASSETS используется в ProfilePage.tsx

export type Assets = {
  // Плейсхолдеры
  avatarPlaceholder: string;
  coverPlaceholder: string;
  noPhoto: string;

  // Брендинг
  logoLight: string;
  logoDark: string;

  // Иконки типов точек/пинов (если нужно в будущем)
  pins: {
    catch: string;
    place: string;
    shop: string;
    base: string;
    slip: string;
    farm: string;
    club: string;
    event: string;
  };
};

export const ASSETS: Assets = {
  // Путь можно поменять под вашу сборку (public/assets или src/assets)
  avatarPlaceholder: "/assets/placeholder/avatar.png",
  coverPlaceholder: "/assets/placeholder/cover.jpg",
  noPhoto: "/assets/placeholder/no-photo.jpg",

  logoLight: "/assets/brand/logo-light.svg",
  logoDark: "/assets/brand/logo-dark.svg",

  pins: {
    catch: "/assets/pins/catch.svg",
    place: "/assets/pins/place.svg",
    shop: "/assets/pins/shop.svg",
    base: "/assets/pins/base.svg",
    slip: "/assets/pins/slip.svg",
    farm: "/assets/pins/farm.svg",
    club: "/assets/pins/club.svg",
    event: "/assets/pins/event.svg",
  },
};

// Дополнительно можно экспортировать прочие UI-константы,
// но ProfilePage.tsx критично требует именно именованный экспорт ASSETS.
TS

echo "✓ Обновлён файл: $FILE"