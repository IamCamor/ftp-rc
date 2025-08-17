/// <reference types="vite/client" />
interface ImportMetaEnv {
  readonly VITE_API_BASE: string
  readonly VITE_USE_MOCKS?: string
  readonly VITE_MAPBOX_TOKEN?: string
  readonly VITE_MAP_PROVIDER?: string
  readonly VITE_UI_PRIMARY?: string
  readonly VITE_UI_ACCENT?: string
  readonly VITE_UI_GLASS_OPACITY?: string
  readonly VITE_UI_GLASS_BLUR?: string
  readonly VITE_UI_PATTERN?: string
}
interface ImportMeta { readonly env: ImportMetaEnv }