export function getQueryParam(name: string): string | null {
  const url = new URL(window.location.href);
  return url.searchParams.get(name);
}
export function removeQueryParams(...keys: string[]) {
  const url = new URL(window.location.href);
  keys.forEach(k => url.searchParams.delete(k));
  window.history.replaceState({}, "", url.toString());
}
