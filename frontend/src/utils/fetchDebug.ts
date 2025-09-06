/**
 * Примитивный логгер fetch для dev.
 * В проде не активируется (NODE_ENV !== 'development').
 */
if (import.meta && import.meta.env && import.meta.env.DEV) {
  const orig = window.fetch;
  window.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const method = (init?.method || 'GET').toUpperCase();
    const url = typeof input === 'string' ? input : (input as URL).toString();
    // eslint-disable-next-line no-console
    console.debug('🛰️ fetch →', method, url, init?.body ? 'with body' : '');
    const t0 = performance.now();
    try {
      const res = await orig(input, init);
      const dt = (performance.now() - t0).toFixed(0);
      // eslint-disable-next-line no-console
      console.debug('✅ fetch ←', res.status, method, url, `${dt}ms`);
      return res;
    } catch (e:any) {
      const dt = (performance.now() - t0).toFixed(0);
      // eslint-disable-next-line no-console
      console.debug('❌ fetch ×', method, url, `${dt}ms`, e?.message || e);
      throw e;
    }
  };
}
export {};
