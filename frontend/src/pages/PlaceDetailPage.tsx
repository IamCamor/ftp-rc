import React from 'react';

export default function PlaceDetailPage({id}:{id:string}){
  return (
    <div className="container" style={{padding:'12px 16px 90px'}}>
      <div className="glass card">
        <h2>Место #{id}</h2>
        <div className="small">Страница места (карточка, список уловов — будет расширяться).</div>
      </div>
    </div>
  );
}
