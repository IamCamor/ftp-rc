export type OAuthProvider = "google" | "apple" | "vk" | "yandex";
const API_BASE = (import.meta as any).env?.VITE_API_BASE?.toString().trim() || "";

export function startOAuth(provider: OAuthProvider) {
  // Backend должен уметь принять return_uri и после колбэка вернуть token и needs_profile=1|0.
  const returnUri = encodeURIComponent(window.location.href);
  window.location.href = `${API_BASE}/auth/${provider}/redirect?return_uri=${returnUri}`;
}
