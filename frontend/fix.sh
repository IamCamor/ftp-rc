#!/bin/bash
set -e

echo "=== FishTrackPro UI setup: Material Symbols icons ==="


# 2. Стили
mkdir -p frontend/src/styles
cat > frontend/src/styles/material-icons.css <<'EOF'
.material-symbols-rounded {
  font-family: 'Material Symbols Rounded';
  font-weight: normal;
  font-style: normal;
  font-size: 24px;
  line-height: 1;
  letter-spacing: normal;
  text-transform: none;
  display: inline-block;
  white-space: nowrap;
  word-wrap: normal;
  direction: ltr;
  -webkit-font-feature-settings: 'liga';
  -webkit-font-smoothing: antialiased;

  font-variation-settings:
    'FILL' 0,
    'wght' 400,
    'GRAD' 0,
    'opsz' 24;
}
EOF

# 3. Конфиг
mkdir -p frontend/src/config
cat > frontend/src/config/ui.ts <<'EOF'
export const UI = {
  icons: {
    nav: {
      map: "map",
      feed: "dynamic_feed",
      alerts: "notifications",
      profile: "account_circle",
    },
    actions: {
      like: "favorite",
      liked: "favorite",
      comment: "mode_comment",
      share: "ios_share",
    },
    appbar: {
      weather: "cloud",
      notifications: "notifications",
      points: "place",
      add: "add_circle",
    },
  },
};
EOF

# 4. Компонент Icon
mkdir -p frontend/src/components
cat > frontend/src/components/Icon.tsx <<'EOF'
import React from "react";

type Props = {
  name: string;
  size?: number;
  fill?: 0 | 1;
  weight?: 100|200|300|400|500|600|700;
  grad?: number;
  className?: string;
  title?: string;
};

export default function Icon({
  name,
  size = 24,
  fill = 0,
  weight = 400,
  grad = 0,
  className = "",
  title,
}: Props) {
  const style: React.CSSProperties = {
    fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' ${grad}, 'opsz' ${size}`,
    fontSize: size,
  };
  return (
    <span
      className={`material-symbols-rounded ${className}`}
      style={style}
      aria-hidden={title ? undefined : true}
      title={title}
    >
      {name}
    </span>
  );
}
EOF

echo "=== Done. Теперь импортируйте стили в main.tsx: ==="
echo "import './styles/material-icons.css';"

# 1. Подключение Google Fonts в index.html
INDEX_HTML="frontend/index.html"
if ! grep -q "Material+Symbols+Rounded" "$INDEX_HTML"; then
  echo "Патчим $INDEX_HTML"
  sed -i '/<head>/a \
  <link rel="preconnect" href="https://fonts.googleapis.com" />\n  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />\n  <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:FILL,wght,GRAD,opsz@0,400,0,24" rel="stylesheet" />' "$INDEX_HTML"
fi