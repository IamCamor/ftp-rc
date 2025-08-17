// Глобальный UI-конфиг и типы

export interface AppBrand {
  name: string
  logo: string
  pattern: string
  primaryColor: string
  accentColor: string
}

export interface UIConfig {
  brand: AppBrand
  glass?: {
    blur: string
    opacity: number
  }
}

export const uiConfig: UIConfig = {
  brand: {
    name: "FishTrackPro",
    logo: "/logo.svg",
    pattern: "/pattern.svg",
    primaryColor: "#1976d2",
    accentColor: "#ff9800",
  },
  glass: {
    blur: "12px",
    opacity: 0.8,
  },
}
