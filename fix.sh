#!/usr/bin/env bash
set -euo pipefail

FRONTEND_DIR="frontend"
SRC_DIR="$FRONTEND_DIR/src"

if [ ! -d "$FRONTEND_DIR" ]; then
  echo "❌ Не найдена папка $FRONTEND_DIR (запусти из корня репо)."
  exit 1
fi

cleanup_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  local first
  first="$(head -n1 "$f" || true)"
  if [ "$first" = '"$@"' ]; then
    tail -n +2 "$f" > "$f.__tmp__" && mv "$f.__tmp__" "$f"
    echo "✔ убран префикс \"\$@\" в: $f"
  fi
}

echo "→ Чищу лишний префикс \"\$@\" в исходниках…"
while IFS= read -r -d '' f; do cleanup_file "$f"; done < <(find "$SRC_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.css" \) -print0)

APP_TSX="$SRC_DIR/App.tsx"
MAIN_TSX="$SRC_DIR/main.tsx"

# На всякий случай подчистим App.tsx
cleanup_file "$APP_TSX"

echo "→ Перезаписываю main.tsx безопасным импортом App (default ИЛИ named)…"
cat > "$MAIN_TSX" <<'TSX'
import React from "react";
import { createRoot } from "react-dom/client";
import * as AppModule from "./App";

// Берём default, либо именованный App/Root, чтобы сборка не падала
const Picked =
  (AppModule as any).default ??
  (AppModule as any).App ??
  (AppModule as any).Root ??
  (() => React.createElement("div", { style:{padding:16,fontFamily:"system-ui"} }, "❗ App component not found in ./App.tsx"));

const el = document.getElementById("root");
if (!el) {
  const div = document.createElement("div");
  div.id = "root";
  document.body.appendChild(div);
  createRoot(div).render(React.createElement(Picked));
} else {
  createRoot(el).render(React.createElement(Picked));
}
TSX

echo "→ Убеждаюсь, что зависимости установлены и собираю…"
( cd "$FRONTEND_DIR" && \
  npm i --legacy-peer-deps && \
  npm run build )

echo "✅ Готово: сборка проходит. Если где-то ещё вылезет \"\$@\" — запусти скрипт повторно."