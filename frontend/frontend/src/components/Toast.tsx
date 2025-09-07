import React, { useEffect, useState } from 'react';

let pushImpl: ((msg:string)=>void) | null = null;
export function pushToast(msg:string){ pushImpl?.(msg); }

const ToastHost: React.FC = () => {
  const [list, setList] = useState<Array<{id:number; text:string}>>([]);
  useEffect(()=>{
    pushImpl = (text: string)=>{
      const id = Date.now() + Math.random();
      setList(prev => [...prev, {id, text}]);
      setTimeout(()=> setList(prev => prev.filter(x=>x.id!==id)), 3000);
    };
    return ()=>{ pushImpl = null; };
  },[]);
  return (
    <div style={{
      position:'fixed', left:0, right:0, bottom:86, display:'grid', gap:8,
      padding:'0 12px', pointerEvents:'none', zIndex:50
    }}>
      {list.map(i=>(
        <div key={i.id} className="glass card" style={{pointerEvents:'auto', justifySelf:'center'}}>
          {i.text}
        </div>
      ))}
    </div>
  );
};

export default ToastHost;
