# FishTrackPro — патч подключения к реальному API
Файлы:
- `src/ui/data/http.ts` — axios-инстанс (токен из localStorage -> Authorization).
- `src/ui/data/api.ts` — функции API (auth, map, catches, feed, admin).
- `src/ui/components/AuthBanner.tsx` — баннер входа (демо-аккаунт).
- `src/ui/components/AddDialog.tsx` — отправка форм в API (или моки).
- `src/ui/screens/FeedScreen.tsx` — лента из API, лайки/комментарии.
- `src/ui/App.patch.txt` — вставь `<AuthBanner/>` и future-флаги роутера.

## Применение
1. Распакуй патч в папку `frontend`.
2. В `.env` фронта поставь:
   ```
   VITE_USE_MOCKS=false
   VITE_API_BASE=http://localhost/api
   ```
3. `npm i axios` (если нет), затем `npm run dev`.
4. Вверху появится баннер входа. Демо: `demo@fishtrackpro.ru` / `password`.
5. Добавление улова/точки, лайки/комменты — теперь через API.
