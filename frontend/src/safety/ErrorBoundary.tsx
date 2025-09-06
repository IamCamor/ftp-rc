import React from 'react';

type Props = { children: React.ReactNode };
type State = { error: any };

export default class ErrorBoundary extends React.Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: any) {
    return { error };
  }

  componentDidCatch(error: any, info: any) {
    // лог в консоль
    console.error('[ErrorBoundary]', error, info);
    (window as any).__FTP_LAST_ERROR__ = { error, info };
  }

  render() {
    if (this.state.error) {
      return (
        <div style={{padding:16,fontFamily:'system-ui,-apple-system,Segoe UI,Roboto',color:'#fff',
          background:'linear-gradient(135deg,rgba(20,20,30,.7),rgba(20,20,30,.5))',backdropFilter:'blur(10px)',minHeight:'100vh'}}>
          <h2 style={{margin:'8px 0'}}>Упс, что-то пошло не так</h2>
          <pre style={{whiteSpace:'pre-wrap',background:'rgba(0,0,0,.2)',padding:12,borderRadius:8}}>
{String(this.state.error?.message || this.state.error)}
          </pre>
          <p>Откройте консоль браузера — там подробности. Временная заглушка показывает оболочку приложения.</p>
          <button onClick={()=>location.reload()} style={{marginTop:12,padding:'8px 12px',borderRadius:8}}>Перезагрузить</button>
        </div>
      );
    }
    return this.props.children;
  }
}

// Диаг-панель по ?diag=1
(function(){
  try {
    const u=new URL(window.location.href);
    if(u.searchParams.get('diag')==='1'){
      const box=document.createElement('div');
      box.style.cssText='position:fixed;bottom:10px;right:10px;z-index:99999;background:rgba(0,0,0,.75);color:#0f0;font:12px/1.4 monospace;padding:10px;border-radius:8px;max-width:40vw;max-height:40vh;overflow:auto';
      const log=(...a:any[])=>{ const p=document.createElement('div'); p.textContent=a.map(x=>typeof x==='object'?JSON.stringify(x):String(x)).join(' '); box.appendChild(p); };
      (window as any).__FTP_DIAG_LOG__ = log;
      log('diag=1 enabled');
      log('build time:', String((import.meta as any).env?.VITE_BUILD_TIME||'n/a'));
      document.body.appendChild(box);
      window.addEventListener('error',e=>log('win.error:',e.message));
      window.addEventListener('unhandledrejection',(e:any)=>log('unhandledrejection', e?.reason));
    }
  } catch {}
})();
