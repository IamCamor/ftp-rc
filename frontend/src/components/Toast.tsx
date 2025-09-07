import React from 'react';
let subs: ((msg:string)=>void)[] = [];
export function pushToast(msg:string){ subs.forEach(fn=>fn(msg)); }

const ToastHost: React.FC = () => {
  const [queue,setQueue] = React.useState<string[]>([]);
  React.useEffect(()=> {
    const fn = (m:string)=> setQueue(q=>[...q,m].slice(-3));
    subs.push(fn);
    return ()=> { subs = subs.filter(s=>s!==fn); };
  }, []);
  React.useEffect(()=> {
    if(!queue.length) return;
    const t = setTimeout(()=> setQueue(q=>q.slice(1)), 2800);
    return ()=> clearTimeout(t);
  }, [queue]);
  return (
    <div style={{position:'fixed', bottom:16, left:16, zIndex:9999, display:'grid', gap:8}}>
      {queue.map((m,i)=>(
        <div key={i} className="glass card" style={{padding:'10px 12px', backdropFilter:'blur(8px)'}}>
          {m}
        </div>
      ))}
    </div>
  );
};
export default ToastHost;
