#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SRC="$ROOT/src"
[ -d "$ROOT/frontend/src" ] && SRC="$ROOT/frontend/src"

mkdir -p "$SRC/components" "$SRC/pages" "$SRC/assets"

echo "→ Using SRC: $SRC"

############################################
# 0) Глобально убрать /api/v1 у авторизации
############################################
echo "→ Rewriting any '/api/v1/auth/' to '/auth/' ..."
# используем perl для кроссплатформенной замены (macOS/Linux)
if compgen -G "$SRC/**/*.ts*" > /dev/null; then
  perl -0777 -pi -e "s#/api/v1/auth/#/auth/#g" $(find "$SRC" -type f \( -name "*.ts" -o -name "*.tsx" \))
else
  find "$SRC" -type f \( -name "*.ts" -o -name "*.tsx" \) -print0 | xargs -0 perl -0777 -pi -e "s#/api/v1/auth/#/auth/#g"
fi

############################################
# 1) config.ts — гарантируем authBase и routes
############################################
CONF="$SRC/config.ts"
if [ -f "$CONF" ]; then
  echo "→ Updating $CONF"
  # Добавим authBase, если его нет
  if ! grep -q "authBase" "$CONF"; then
    perl -0777 -pi -e "s#apiBase\s*:\s*['\"][^'\"]+['\"]#apiBase: 'https://api.fishtrackpro.ru/api/v1',\n  authBase: 'https://api.fishtrackpro.ru'#s" "$CONF" || true
  fi
  # Добавим секцию auth.routes, если нет
  if ! grep -q "routes:" "$CONF"; then
    perl -0777 -pi -e "s#auth:\s*{#auth: {\n    routes: {\n      login: '/auth/login',\n      register: '/auth/register',\n      oauthRedirect: (p: any) => \`/auth/\${p}/redirect\`,\n    },#s" "$CONF" || true
  fi
else
  echo "→ Creating $CONF"
  cat > "$CONF" <<'TS'
export type Providers = { google:boolean; vk:boolean; yandex:boolean; apple:boolean; };
const config = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  authBase: 'https://api.fishtrackpro.ru',
  siteBase: 'https://www.fishtrackpro.ru',
  images: {
    logoUrl: '/assets/logo.svg',
    defaultAvatar: '/assets/default-avatar.png',
    backgroundPattern: '/assets/bg-pattern.png',
  },
  icons: { login:'login', image:'image', save:'save', google:'google', vk:'groups', yandex:'language', apple:'apple' },
  banners: { feedEvery: 5 },
  auth: {
    enabled: true,
    providers: { google:true, vk:true, yandex:true, apple:true } as Providers,
    routes: {
      login: '/auth/login',
      register: '/auth/register',
      oauthRedirect: (p: keyof Providers) => `/auth/${p}/redirect`,
    },
    links: {
      privacy: 'https://www.fishtrackpro.ru/docs/privacy',
      offer:   'https://www.fishtrackpro.ru/docs/offer',
      terms:   'https://www.fishtrackpro.ru/docs/terms',
    },
    username: { min:3, max:24, pattern: /^[a-zA-Z0-9._-]+$/ as unknown as RegExp },
    requireAuthForWeatherSave: true,
  }
};
export default config;
TS
fi

############################################
# 2) api.ts — login/register/oauth только на authBase
############################################
API="$SRC/api.ts"
echo "→ (Re)writing $API auth helpers"
# Сохраняем вашу текущую логику данных, но переопределяем блок AUTH
# Если файла нет — создаём минимальный с базовыми методами
if [ ! -f "$API" ]; then
  cat > "$API" <<'TS'
import config from './config';
type HttpOptions = { method?: 'GET'|'POST'|'PUT'|'PATCH'|'DELETE'; body?: any; auth?: boolean; headers?: Record<string,string>; };
function getToken(): string | null { try { return localStorage.getItem('token'); } catch { return null; } }
export function isAuthed(){ return !!getToken(); }
export function logout(){ try { localStorage.removeItem('token'); } catch {} }
async function http<T=any>(url: string, opts: HttpOptions = {}): Promise<T> {
  const { method='GET', body, auth=true, headers={} } = opts;
  const token = getToken();
  const res = await fetch(url, {
    method, mode:'cors', credentials:'omit',
    headers: { 'Accept':'application/json', ...(body?{'Content-Type':'application/json'}:{}), ...(auth&&token?{'Authorization':`Bearer ${token}`}:{}), ...headers },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text().catch(()=> ''); let data:any=null; try{ data = text?JSON.parse(text):null }catch{ data=text }
  if(!res.ok){ const msg=(data&&(data.message||data.error))||`${res.status} ${res.statusText}`; const err:any=new Error(msg); err.status=res.status; err.payload=data; throw err; }
  return (data??undefined) as T;
}
const base = config.apiBase; const authBase = config.authBase;
/** AUTH only on authBase */
export async function login(email:string, password:string){
  const r = await http<{token?:string;[k:string]:any}>(`${authBase}/auth/login`, {method:'POST', body:{email,password}, auth:false});
  if(r?.token) localStorage.setItem('token', r.token); return r;
}
export async function register(name:string, email:string, password:string, username?:string, avatarUrl?:string){
  const body:any={name,email,password}; if(username) body.username=username; if(avatarUrl) body.photo_url=avatarUrl;
  const r = await http<{token?:string;[k:string]:any}>(`${authBase}/auth/register`, {method:'POST', body, auth:false});
  if(r?.token) localStorage.setItem('token', r.token); return r;
}
export function oauthStart(provider:'google'|'vk'|'yandex'|'apple'){ window.location.href = `${authBase}/auth/${provider}/redirect`; }
TS
else
  # Перепишем/вставим блок AUTH в существующий файл
  perl -0777 -pi -e "s#export\s+async\s+function\s+login[\\s\\S]*?\\}#/* replaced by patch */#g" "$API" || true
  perl -0777 -pi -e "s#export\s+async\s+function\s+register[\\s\\S]*?\\}#/* replaced by patch */#g" "$API" || true
  perl -0777 -pi -e "s#export\s+function\s+oauthStart[\\s\\S]*?\\}#/* replaced by patch */#g" "$API" || true
  # Убедимся, что импортирован config и есть authBase
  if ! grep -q "import config from './config'" "$API"; then
    sed -i.bak '1i\
import config from '"'"'./config'"'"';
' "$API" || perl -0777 -pi -e "s#^#import config from './config';\n#s" "$API"
  fi
  if ! grep -q "const authBase" "$API"; then
    echo "const authBase = config.authBase;" >> "$API"
  fi
  cat >> "$API" <<'TS'

// ---- AUTH (patched) ----
export async function login(email:string, password:string){
  const r = await (await import('./api')).defaultFetch?.(`${config.authBase}/auth/login`)?.catch?.(()=>null);
  // если defaultFetch отсутствует — используем локальный http:
  // @ts-ignore
  if(!r){
    const http = (await import('./api')).http || (async (u:string,o:any)=> { const res=await fetch(u,{method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json'},body:JSON.stringify(o.body)}); return res.json(); });
  }
  // финальная реализация
  const res = await fetch(`${config.authBase}/auth/login`, {method:'POST', headers:{'Content-Type':'application/json','Accept':'application/json'}, body: JSON.stringify({email,password})});
  const data = await res.json();
  if(!res.ok) throw new Error(data?.message||'Login failed');
  if(data?.token) localStorage.setItem('token', data.token);
  return data;
}
export async function register(name:string, email:string, password:string, username?:string, avatarUrl?:string){
  const body:any={name,email,password}; if(username) body.username=username; if(avatarUrl) body.photo_url=avatarUrl;
  const res = await fetch(`${config.authBase}/auth/register`, {method:'POST', headers:{'Content-Type':'application/json','Accept':'application/json'}, body: JSON.stringify(body)});
  const data = await res.json();
  if(!res.ok) throw new Error(data?.message||'Register failed');
  if(data?.token) localStorage.setItem('token', data.token);
  return data;
}
export function oauthStart(provider:'google'|'vk'|'yandex'|'apple'){
  window.location.href = `${config.authBase}/auth/${provider}/redirect`;
}
TS
fi

############################################
# 3) Компонент чекбоксов согласий
############################################
cat > "$SRC/components/LegalCheckboxes.tsx" <<'TS'
import React from 'react';
import config from '../config';

type Props = {
  checkedPrivacy: boolean;
  checkedOffer: boolean;
  checkedTerms: boolean;
  onChange: (p: {privacy?:boolean; offer?:boolean; terms?:boolean})=>void;
};
const LegalCheckboxes: React.FC<Props> = ({checkedPrivacy, checkedOffer, checkedTerms, onChange})=>{
  const L = config.auth.links;
  return (
    <div style={{display:'grid', gap:8, fontSize:14}}>
      <label style={{display:'flex', gap:8, alignItems:'flex-start'}}>
        <input type="checkbox" checked={checkedPrivacy} onChange={e=>onChange({privacy:e.target.checked})}/>
        <span>Соглашаюсь с <a href={L.privacy} target="_blank" rel="noreferrer">политикой обработки персональных данных</a>.</span>
      </label>
      <label style={{display:'flex', gap:8, alignItems:'flex-start'}}>
        <input type="checkbox" checked={checkedOffer} onChange={e=>onChange({offer:e.target.checked})}/>
        <span>Принимаю <a href={L.offer} target="_blank" rel="noreferrer">оферту</a>.</span>
      </label>
      <label style={{display:'flex', gap:8, alignItems:'flex-start'}}>
        <input type="checkbox" checked={checkedTerms} onChange={e=>onChange({terms:e.target.checked})}/>
        <span>Согласен с <a href={L.terms} target="_blank" rel="noreferrer">правилами пользования</a>.</span>
      </label>
    </div>
  );
};
export default LegalCheckboxes;
TS

############################################
# 4) Страницы /login и /register
############################################
cat > "$SRC/pages/AuthLoginPage.tsx" <<'TS'
import React from 'react';
import { login, oauthStart } from '../api';
import config from '../config';

const AuthLoginPage: React.FC = ()=>{
  const [email,setEmail] = React.useState('');
  const [password,setPassword] = React.useState('');
  const [error,setError] = React.useState<string|undefined>();

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    setError(undefined);
    try{
      await login(email, password);
      window.location.href = '/';
    }catch(err:any){
      setError(err?.message || 'Ошибка входа');
    }
  }

  const p = config.auth.providers;

  return (
    <div className="container" style={{maxWidth:420}}>
      <h2>Вход</h2>
      {error && <div className="glass card" style={{color:'crimson'}}>{error}</div>}
      <form onSubmit={onSubmit} className="glass card" style={{display:'grid', gap:12}}>
        <input placeholder="Email" type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
        <input placeholder="Пароль" type="password" value={password} onChange={e=>setPassword(e.target.value)} required />
        <button className="btn primary" type="submit">Войти</button>
      </form>

      <div className="glass card" style={{marginTop:12}}>
        <div style={{display:'grid', gap:8}}>
          {p.google && <button className="btn" onClick={()=>oauthStart('google')}>Войти через Google</button>}
          {p.vk     && <button className="btn" onClick={()=>oauthStart('vk')}>Войти через VK</button>}
          {p.yandex && <button className="btn" onClick={()=>oauthStart('yandex')}>Войти через Яндекс</button>}
          {p.apple  && <button className="btn" onClick={()=>oauthStart('apple')}>Войти через Apple</button>}
        </div>
      </div>

      <div style={{marginTop:12}}>
        Нет аккаунта? <a href="/register">Зарегистрироваться</a>
      </div>
    </div>
  );
};
export default AuthLoginPage;
TS

cat > "$SRC/pages/AuthRegisterPage.tsx" <<'TS'
import React from 'react';
import { register, oauthStart } from '../api';
import config from '../config';
import LegalCheckboxes from '../components/LegalCheckboxes';

const AuthRegisterPage: React.FC = ()=>{
  const [name,setName] = React.useState('');
  const [username,setUsername] = React.useState('');
  const [email,setEmail] = React.useState('');
  const [password,setPassword] = React.useState('');
  const [agree,setAgree] = React.useState({privacy:false, offer:false, terms:false});
  const [error,setError] = React.useState<string|undefined>();

  const usernameCfg = config.auth.username;

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    setError(undefined);
    if(!(agree.privacy && agree.offer && agree.terms)){
      setError('Необходимо принять все согласия.');
      return;
    }
    if(username && (username.length < usernameCfg.min || username.length > usernameCfg.max)){
      setError(`Логин от ${usernameCfg.min} до ${usernameCfg.max} символов`);
      return;
    }
    try{
      await register(name, email, password, username);
      window.location.href = '/';
    }catch(err:any){
      setError(err?.message || 'Ошибка регистрации');
    }
  }

  const p = config.auth.providers;

  return (
    <div className="container" style={{maxWidth:480}}>
      <h2>Регистрация</h2>
      {error && <div className="glass card" style={{color:'crimson'}}>{error}</div>}
      <form onSubmit={onSubmit} className="glass card" style={{display:'grid', gap:12}}>
        <input placeholder="Имя" value={name} onChange={e=>setName(e.target.value)} required />
        <input placeholder="Логин (a-z, 0-9, . _ -)" value={username} onChange={e=>setUsername(e.target.value)} />
        <input placeholder="Email" type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
        <input placeholder="Пароль" type="password" value={password} onChange={e=>setPassword(e.target.value)} required />

        <LegalCheckboxes
          checkedPrivacy={agree.privacy}
          checkedOffer={agree.offer}
          checkedTerms={agree.terms}
          onChange={(p)=> setAgree(prev=>({...prev, ...p}))}
        />

        <button className="btn primary" type="submit">Зарегистрироваться</button>
      </form>

      <div className="glass card" style={{marginTop:12}}>
        <div style={{display:'grid', gap:8}}>
          {p.google && <button className="btn" onClick={()=>oauthStart('google')}>Через Google</button>}
          {p.vk     && <button className="btn" onClick={()=>oauthStart('vk')}>Через VK</button>}
          {p.yandex && <button className="btn" onClick={()=>oauthStart('yandex')}>Через Яндекс</button>}
          {p.apple  && <button className="btn" onClick={()=>oauthStart('apple')}>Через Apple</button>}
        </div>
      </div>

      <div style={{marginTop:12}}>
        Уже есть аккаунт? <a href="/login">Войти</a>
      </div>
    </div>
  );
};
export default AuthRegisterPage;
TS

############################################
# 5) Роутер: /login и /register
############################################
APP_SHELL="$SRC/AppShell.tsx"
if [ -f "$APP_SHELL" ]; then
  echo "→ Updating routes in $APP_SHELL (if needed)"
  # вставим импорты, если их нет
  if ! grep -q "AuthLoginPage" "$APP_SHELL"; then
    perl -0777 -pi -e "s#import React.*?from 'react';#import React from 'react';\nimport AuthLoginPage from './pages/AuthLoginPage';\nimport AuthRegisterPage from './pages/AuthRegisterPage';#s" "$APP_SHELL"
  fi
  # добавим маршруты
  if ! grep -q 'path="/login"' "$APP_SHELL"; then
    perl -0777 -pi -e "s#<Routes>#<Routes>\n        <Route path=\"/login\" element={<AuthLoginPage/>} />\n        <Route path=\"/register\" element={<AuthRegisterPage/>} />#s" "$APP_SHELL"
  fi
else
  echo "→ Creating $APP_SHELL with basic router"
  cat > "$APP_SHELL" <<'TS'
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import ToastHost from './components/Toast';
import AuthLoginPage from './pages/AuthLoginPage';
import AuthRegisterPage from './pages/AuthRegisterPage';
const AppShell: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<AuthLoginPage/>} />
        <Route path="/register" element={<AuthRegisterPage/>} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
      <ToastHost/>
    </BrowserRouter>
  );
};
export default AppShell;
TS
fi

############################################
# 6) main.tsx — базовая точка входа, если вдруг отсутствует
############################################
MAIN="$SRC/main.tsx"
if [ ! -f "$MAIN" ]; then
  echo "→ Creating $MAIN"
  cat > "$MAIN" <<'TS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import AppShell from './AppShell';
const el = document.getElementById('root')!;
createRoot(el).render(<AppShell/>);
console.log('[boot] App mounted');
TS
fi

############################################
# 7) Отчёт
############################################
echo "→ Grep auth usages after patch:"
grep -RIn "api/v1/auth" "$SRC" || echo "✓ No /api/v1/auth occurrences left"

echo "✅ Done. Now run: npm run build && npm run preview"