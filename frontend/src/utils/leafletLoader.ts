let cached: any = null;
export async function loadLeaflet() {
  if (cached) return cached;
  const L = await import('leaflet');
  // Без CSS Leaflet маркеры не видны — оставим подсказку в README
  return cached = L;
}
