#!/usr/bin/env bash
set -euo pipefail

API_FILE="frontend/src/api.ts"

if [ ! -f "$API_FILE" ]; then
  echo "❌ Не найден $API_FILE — запустите скрипт из корня проекта."
  exit 1
fi

cp "$API_FILE" "${API_FILE}.bak"
echo "🧷 Бэкап: ${API_FILE}.bak"

need_newline() {
  # Добавим перевод строки в конце файла, если его нет
  tail -c1 "$API_FILE" | read -r _ || echo >> "$API_FILE"
}

# 1) Добавим catchById, если отсутствует
if grep -qE 'export\s+async\s+function\s+catchById\s*\(' "$API_FILE"; then
  echo "• catchById() уже существует — пропускаю."
else
  need_newline
  cat >> "$API_FILE" <<'TS'

// --- auto-added: catchById ---
/**
 * Получить улов по ID
 * GET /catch/{id}
 * Требует, чтобы в файле выше был определён `const base = config.apiBase`
 */
export async function catchById(id: number | string): Promise<any> {
  const url = `${base}/catch/${id}`;
  const token = (typeof localStorage !== 'undefined') ? localStorage.getItem('token') : null;
  const res = await fetch(url, {
    method: 'GET',
    headers: {
      'Accept': 'application/json',
      ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    },
    credentials: 'include',
  });
  if (!res.ok) {
    throw new Error(`catchById failed: ${res.status} ${res.statusText}`);
  }
  return res.json();
}
// --- /auto-added: catchById ---
TS
  echo "✅ Добавлен export catchById()"
fi

# 2) Добавим addCatchComment, если отсутствует
if grep -qE 'export\s+async\s+function\s+addCatchComment\s*\(' "$API_FILE"; then
  echo "• addCatchComment() уже существует — пропускаю."
else
  need_newline
  cat >> "$API_FILE" <<'TS'

// --- auto-added: addCatchComment ---
/**
 * Добавить комментарий к улову
 * POST /catch/{id}/comments
 * Бек ожидает JSON с текстом комментария. Чаще всего поле называется "text".
 */
export async function addCatchComment(
  catchId: number | string,
  text: string
): Promise<any> {
  const url = `${base}/catch/${catchId}/comments`;
  const token = (typeof localStorage !== 'undefined') ? localStorage.getItem('token') : null;

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    },
    credentials: 'include',
    body: JSON.stringify({ text }),
  });

  // Если валидация на беке требует другое имя поля (например, "message"),
  // можно попробовать повторить с fallback:
  if (res.status === 422) {
    // попробуем "message" вместо "text"
    const retry = await fetch(url, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
      },
      credentials: 'include',
      body: JSON.stringify({ message: text }),
    });
    if (!retry.ok) {
      const t = await retry.text().catch(() => '');
      throw new Error(`addCatchComment failed: ${retry.status} ${retry.statusText} ${t}`);
    }
    try { return await retry.json(); } catch { return { ok: true }; }
  }

  if (!res.ok) {
    const t = await res.text().catch(() => '');
    throw new Error(`addCatchComment failed: ${res.status} ${res.statusText} ${t}`);
  }
  try { return await res.json(); } catch { return { ok: true }; }
}
// --- /auto-added: addCatchComment ---
TS
  echo "✅ Добавлен export addCatchComment()"
fi

echo "🎯 Готово. Теперь пересоберите фронт:"
echo "   cd frontend && npm run build"