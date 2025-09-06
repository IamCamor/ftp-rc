let loading: Promise<any> | null = null;
export async function loadLeaflet(): Promise<any> {
  if ((window as any).L) return (window as any).L;
  if (!loading) {
    loading = new Promise((resolve, reject) => {
      const css = document.createElement('link');
      css.rel = 'stylesheet';
      css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      css.onload = () => {};
      css.onerror = reject;
      document.head.appendChild(css);

      const s = document.createElement('script');
      s.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      s.async = true;
      s.onload = () => resolve((window as any).L);
      s.onerror = reject;
      document.body.appendChild(s);
    });
  }
  return loading;
}
