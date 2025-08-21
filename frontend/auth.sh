#!/usr/bin/env bash
set -euo pipefail

echo "▶️ Patch: OAuth провайдеры + согласие + мастер профиля"

ROOT="$(pwd)"
SRC="$ROOT/src"
DATA="$SRC/data"
COMP="$SRC/components"
UTILS="$SRC/utils"

mkdir -p "$SRC" "$DATA" "$COMP" "$UTILS"

############################################
# .env.example — новые переменные окружения
############################################
if ! grep -q "VITE_LEGAL_TERMS_URL" "$ROOT/.env.example" 2>/dev/null; then
cat >> "$ROOT/.env.example" <<'ENV'

# Ссылки на документы
VITE_LEGAL_TERMS_URL=https://fishtrackpro.ru/terms
VITE_LEGAL_PRIVACY_URL=https://fishtrackpro.ru/privacy

# Флаги доступности OAuth-провайдеров
VITE_OAUTH_GOOGLE=1
VITE_OAUTH_APPLE=1
VITE_OAUTH_VK=1
VITE_OAUTH_YANDEX=1
ENV
fi

############################################
# utils: query-параметры + slugify
############################################
cat > "$UTILS/url.ts" <<'TS'
export function getQueryParam(name: string): string | null {
  const url = new URL(window.location.href);
  return url.searchParams.get(name);
}
export function removeQueryParams(...keys: string[]) {
  const url = new URL(window.location.href);
  keys.forEach(k => url.searchParams.delete(k));
  window.history.replaceState({}, "", url.toString());
}
TS

cat > "$UTILS/slugify.ts" <<'TS'
export function slugify(input: string): string {
  return input
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9_]+/g, "-")
    .replace(/(^-|-$)/g, "")
    .substring(0, 24);
}
TS

############################################
# components: чекбокс согласия
############################################
cat > "$COMP/ToSCheckbox.tsx" <<'TSX'
import React from "react";

export default function ToSCheckbox({checked,onChange}:{checked:boolean;onChange:(v:boolean)=>void}) {
  const terms = (import.meta as any).env?.VITE_LEGAL_TERMS_URL || "#";
  const privacy = (import.meta as any).env?.VITE_LEGAL_PRIVACY_URL || "#";
  return (
    <label className="flex items-start gap-2 text-sm text-gray-700">
      <input type="checkbox" className="mt-1" checked={checked} onChange={e=>onChange(e.target.checked)} />
      <span>
        Я принимаю {" "}
        <a className="underline" href={terms} target="_blank" rel="noreferrer">Пользовательское соглашение</a>
        {" "} и {" "}
        <a className="underline" href={privacy} target="_blank" rel="noreferrer">Политику конфиденциальности</a>.
      </span>
    </label>
  );
}
TSX

############################################
# API: OAuth + мастер профиля
############################################
cat > "$DATA/auth_providers.ts" <<'TS'
export type OAuthProvider = "google" | "apple" | "vk" | "yandex";
const API_BASE = (import.meta as any).env?.VITE_API_BASE?.toString().trim() || "";

export function startOAuth(provider: OAuthProvider) {
  // Backend должен уметь принять return_uri и после колбэка вернуть token и needs_profile=1|0.
  const returnUri = encodeURIComponent(window.location.href);
  window.location.href = `${API_BASE}/auth/${provider}/redirect?return_uri=${returnUri}`;
}
TS

# append/patch into data/api.ts (create if missing minimal)
if [ ! -f "$DATA/api.ts" ]; then
  cat > "$DATA/api.ts" <<'TS'
const API_BASE = (import.meta as any).env?.VITE_API_BASE?.toString().trim() || "";
export async function login(body:{email:string;password:string;}):Promise<{token:string}>{const r=await fetch(`${API_BASE}/api/v1/login`,{method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify(body)}); if(!r.ok) throw new Error("Неверный email или пароль"); return r.json();}
export async function registerUser(body:{email:string;password:string;name:string;}):Promise<{token:string}>{const r=await fetch(`${API_BASE}/api/v1/register`,{method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify(body)}); if(!r.ok) throw new Error("Не удалось зарегистрироваться"); return r.json();}
export async function getMe(){const r=await fetch(`${API_BASE}/api/v1/me`,{headers:{Accept:"application/json"}}); if(!r.ok) throw new Error("Не авторизованы"); return r.json();}
export async function logout(){await fetch(`${API_BASE}/api/v1/logout`,{method:"POST"});}
TS
fi

# idempotent append helpers
node - <<'NODE'
const fs=require('fs'),p='src/data/api.ts';
let t=fs.readFileSync(p,'utf8');
function add(name,code){ if(!t.includes(name)) t += "\n" + code + "\n"; }
add('checkHandleAvailability',`export async function checkHandleAvailability(handle:string){ const API_BASE=(import.meta as any).env?.VITE_API_BASE?.toString().trim()||""; const r=await fetch(\`\${API_BASE}/api/v1/profile/handle-available?handle=\${encodeURIComponent(handle)}\`,{headers:{Accept:"application/json"}}); if(!r.ok) throw new Error("Ошибка проверки"); const j=await r.json(); return !!j?.available; }`);
add('completeProfile',`export async function completeProfile(payload: FormData){ const API_BASE=(import.meta as any).env?.VITE_API_BASE?.toString().trim()||""; const r=await fetch(\`\${API_BASE}/api/v1/profile/setup\`,{ method:"POST", body: payload }); if(!r.ok) throw new Error("Не удалось сохранить профиль"); return r.json(); }`);
add('uploadAvatar',`export async function uploadAvatar(file: File){ const API_BASE=(import.meta as any).env?.VITE_API_BASE?.toString().trim()||""; const fd=new FormData(); fd.append("avatar", file); const r=await fetch(\`\${API_BASE}/api/v1/profile/avatar\`,{ method:"POST", body: fd }); if(!r.ok) throw new Error("Не удалось загрузить аватар"); return r.json(); }`);
fs.writeFileSync(p,t);
console.log("✓ data/api.ts обновлён");
NODE

############################################
# Экран авторизации с провайдерами + мастер профиля
############################################
cat > "$SRC/screens/AuthScreen.tsx" <<'TSX'
import React, { useEffect, useMemo, useState } from "react";
import { login, registerUser, checkHandleAvailability, completeProfile } from "../data/api";
import { setToken } from "../data/auth";
import { startOAuth } from "../data/auth_providers";
import { getQueryParam, removeQueryParams } from "../utils/url";
import { slugify } from "../utils/slugify";
import ToSCheckbox from "../components/ToSCheckbox";

type Mode = "login" | "register" | "complete_profile";

export default function AuthScreen({ onClose }:{ onClose?: ()=>void }) {
  const [mode, setMode] = useState<Mode>("login");

  // Поля email-регистрации/логина
  const [email, setEmail] = useState(""); const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");

  // Мастер профиля
  const [handle, setHandle] = useState("");
  const [dob, setDob] = useState(""); // YYYY-MM-DD
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [bio, setBio] = useState("");
  const [links, setLinks] = useState({ instagram:"", vk:"", telegram:"", website:"" });
  const [agree, setAgree] = useState(false);

  const [checkingHandle, setCheckingHandle] = useState(false);
  const [handleAvailable, setHandleAvailable] = useState<boolean | null>(null);

  // Состояния ошибок/загрузки
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // Флаги провайдеров
  const flags = useMemo(() => ({
    google: (import.meta as any).env?.VITE_OAUTH_GOOGLE === '1' || (import.meta as any).env?.VITE_OAUTH_GOOGLE === 1,
    apple:  (import.meta as any).env?.VITE_OAUTH_APPLE === '1' || (import.meta as any).env?.VITE_OAUTH_APPLE === 1,
    vk:     (import.meta as any).env?.VITE_OAUTH_VK === '1' || (import.meta as any).env?.VITE_OAUTH_VK === 1,
    yandex: (import.meta as any).env?.VITE_OAUTH_YANDEX === '1' || (import.meta as any).env?.VITE_OAUTH_YANDEX === 1,
  }), []);

  // Обработка возврата из OAuth: backend добавляет ?token=...&needs_profile=1|0
  useEffect(() => {
    const t = getQueryParam("token");
    const needs = getQueryParam("needs_profile");
    if (t) {
      setToken(t);
      removeQueryParams("token","needs_profile","state","code");
      if (needs === "1" || needs === "true") {
        setMode("complete_profile");
      } else {
        onClose?.();
      }
    }
  }, [onClose]);

  // Автогенерация handle
  useEffect(() => {
    if (!displayName) return;
    setHandle((h) => h ? h : slugify(displayName));
  }, [displayName]);

  const onCheckHandle = async () => {
    if (!handle) return;
    setCheckingHandle(true); setError(null);
    try { setHandleAvailable(await checkHandleAvailability(handle)); }
    catch(e:any){ setError(e?.message || "Не удалось проверить адрес"); }
    finally{ setCheckingHandle(false); }
  };

  const submitEmail = async (e: React.FormEvent) => {
    e.preventDefault(); setLoading(true); setError(null);
    try {
      if (mode === "login") {
        const { token } = await login({ email, password });
        setToken(token); onClose?.();
      } else {
        const { token } = await registerUser({ email, password, name: displayName || email.split("@")[0] });
        setToken(token);
        setMode("complete_profile");
      }
    } catch (err:any) { setError(err?.message || "Ошибка"); }
    finally { setLoading(false); }
  };

  const submitProfile = async (e: React.FormEvent) => {
    e.preventDefault(); setLoading(true); setError(null);
    try {
      if (!agree) { setError("Нужно принять условия"); setLoading(false); return; }
      const fd = new FormData();
      fd.append("name", displayName);
      fd.append("handle", handle);
      if (dob) fd.append("dob", dob);
      if (bio) fd.append("bio", bio);
      if (links.instagram) fd.append("links[instagram]", links.instagram);
      if (links.vk) fd.append("links[vk]", links.vk);
      if (links.telegram) fd.append("links[telegram]", links.telegram);
      if (links.website) fd.append("links[website]", links.website);
      if (avatarFile) fd.append("avatar", avatarFile);
      await completeProfile(fd);
      onClose?.();
    } catch (err:any) { setError(err?.message || "Не удалось сохранить профиль"); }
    finally { setLoading(false); }
  };

  // Визуалка
  return (
    <div className="fixed inset-0 z-[2000] flex items-center justify-center bg-black/30">
      <div className="glass rounded-2xl w-[92%] max-w-md p-5">
        {mode !== "complete_profile" ? (
          <>
            <div className="flex gap-2 mb-4">
              <button onClick={()=>setMode("login")} className={"flex-1 py-2 rounded-xl "+(mode==="login"?"grad-ig text-white":"glass")}>Вход</button>
              <button onClick={()=>setMode("register")} className={"flex-1 py-2 rounded-xl "+(mode==="register"?"grad-ig text-white":"glass")}>Регистрация</button>
            </div>

            {/* social providers */}
            <div className="grid grid-cols-2 gap-2 mb-3">
              {flags.google && <button onClick={()=>startOAuth("google")} className="glass rounded-xl py-2">Войти через Google</button>}
              {flags.apple  && <button onClick={()=>startOAuth("apple")}  className="glass rounded-xl py-2">Через Apple</button>}
              {flags.vk     && <button onClick={()=>startOAuth("vk")}     className="glass rounded-xl py-2">Через VK</button>}
              {flags.yandex && <button onClick={()=>startOAuth("yandex")} className="glass rounded-xl py-2">Через Yandex</button>}
            </div>

            <div className="text-center text-xs text-gray-500 mb-2">или по email</div>

            <form onSubmit={submitEmail} className="space-y-3">
              {mode === "register" && (
                <div>
                  <label className="text-sm text-gray-700">Отображаемое имя</label>
                  <input className="w-full bg-white/60 rounded-xl p-2 outline-none" value={displayName} onChange={(e)=>setDisplayName(e.target.value)} required />
                </div>
              )}
              <div>
                <label className="text-sm text-gray-700">Email</label>
                <input type="email" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={email} onChange={(e)=>setEmail(e.target.value)} required />
              </div>
              <div>
                <label className="text-sm text-gray-700">Пароль</label>
                <input type="password" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={password} onChange={(e)=>setPassword(e.target.value)} required />
              </div>

              {error && <div className="text-sm text-red-600">{error}</div>}
              <div className="flex gap-2">
                <button disabled={loading} className="flex-1 grad-ig text-white rounded-xl py-2 shadow">
                  {loading ? "…" : (mode === "login" ? "Войти" : "Продолжить")}
                </button>
                <button type="button" onClick={()=>onClose?.()} className="px-3 rounded-xl glass">Отмена</button>
              </div>
            </form>
          </>
        ) : (
          <>
            <div className="text-lg font-semibold mb-3">Завершите профиль</div>
            <form onSubmit={submitProfile} className="space-y-3">
              <div>
                <label className="text-sm text-gray-700">Имя</label>
                <input className="w-full bg-white/60 rounded-xl p-2 outline-none" value={displayName} onChange={(e)=>setDisplayName(e.target.value)} required />
              </div>

              <div>
                <label className="text-sm text-gray-700">Короткий адрес (handle)</label>
                <div className="flex gap-2">
                  <input className="flex-1 bg-white/60 rounded-xl p-2 outline-none" value={handle} onChange={(e)=>{ const v=e.target.value; setHandle(v.replace(/[^a-z0-9_-]/gi,"").toLowerCase()); setHandleAvailable(null); }} required />
                  <button type="button" onClick={onCheckHandle} className="px-3 rounded-xl glass">{checkingHandle?"…":"Проверить"}</button>
                </div>
                {handleAvailable === true && <div className="text-xs text-green-600 mt-1">Доступно</div>}
                {handleAvailable === false && <div className="text-xs text-red-600 mt-1">Занято</div>}
              </div>

              <div>
                <label className="text-sm text-gray-700">Дата рождения</label>
                <input type="date" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={dob} onChange={(e)=>setDob(e.target.value)} />
              </div>

              <div>
                <label className="text-sm text-gray-700">Аватар</label>
                <input type="file" accept="image/*" onChange={(e)=>setAvatarFile(e.target.files?.[0] || null)} />
              </div>

              <div>
                <label className="text-sm text-gray-700">О себе</label>
                <textarea className="w-full bg-white/60 rounded-xl p-2 outline-none" rows={3} value={bio} onChange={(e)=>setBio(e.target.value)} />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div><label className="text-sm">Instagram</label><input placeholder="@username" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={links.instagram} onChange={(e)=>setLinks(s=>({...s,instagram:e.target.value}))} /></div>
                <div><label className="text-sm">VK</label><input placeholder="vk.com/id..." className="w-full bg-white/60 rounded-xl p-2 outline-none" value={links.vk} onChange={(e)=>setLinks(s=>({...s,vk:e.target.value}))} /></div>
                <div><label className="text-sm">Telegram</label><input placeholder="@username" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={links.telegram} onChange={(e)=>setLinks(s=>({...s,telegram:e.target.value}))} /></div>
                <div><label className="text-sm">Сайт</label><input placeholder="https://..." className="w-full bg-white/60 rounded-xl p-2 outline-none" value={links.website} onChange={(e)=>setLinks(s=>({...s,website:e.target.value}))} /></div>
              </div>

              <ToSCheckbox checked={agree} onChange={setAgree} />

              {error && <div className="text-sm text-red-600">{error}</div>}
              <div className="flex gap-2">
                <button disabled={!agree || !displayName || !handle || (handleAvailable===false) || loading} className="flex-1 grad-ig text-white rounded-xl py-2 shadow">
                  {loading ? "…" : "Сохранить"}
                </button>
                <button type="button" onClick={()=>onClose?.()} className="px-3 rounded-xl glass">Позже</button>
              </div>
            </form>
          </>
        )}
      </div>
    </div>
  );
}
TSX

echo "✅ Готово. Что дальше:
1) Проверь .env(.local/.production):
   - VITE_API_BASE=https://api.fishtrackpro.ru
   - VITE_LEGAL_TERMS_URL, VITE_LEGAL_PRIVACY_URL
   - VITE_OAUTH_GOOGLE=1, VITE_OAUTH_APPLE=1, VITE_OAUTH_VK=1, VITE_OAUTH_YANDEX=1
2) На бэкенде должны быть маршруты:
   - POST /api/v1/login
   - POST /api/v1/register
   - GET  /api/v1/me
   - POST /api/v1/logout
   - GET  /auth/{provider}/redirect?return_uri=...
   - (после колбэка) редирект на return_uri?token=...&needs_profile=1|0
   - GET  /api/v1/profile/handle-available?handle=...
   - POST /api/v1/profile/setup  (multipart: name, handle, dob?, bio?, links[...], avatar?)
3) Пересобери фронт:
   npm ci
   npm run dev    # для локальной проверки
   npm run build  # для прод
"
