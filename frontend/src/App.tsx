import React, { useEffect, useState } from 'react';
import Header from './components/Header';
import MapScreen from './screens/MapScreen';
import WeatherScreen from './screens/WeatherScreen';

function useHash(): string {
  const [h,setH]=useState(window.location.hash||'#/map');
  useEffect(()=>{
    const on = ()=>setH(window.location.hash||'#/map');
    window.addEventListener('hashchange',on);
    return ()=>window.removeEventListener('hashchange',on);
  },[]);
  return h;
}

export default function App(){
  const hash = useHash();
  const route = hash.replace(/^#\//,'') || 'map';

  return (
    <div className="w-full h-screen relative bg-gray-50">
      <Header />
      {route==='map' && <MapScreen/>}
      {route==='weather' && <WeatherScreen/>}
      {route!=='map' && route!=='weather' && (
        <div className="pt-20 px-4 text-gray-500">Страница в разработке</div>
      )}
    </div>
  );
}
