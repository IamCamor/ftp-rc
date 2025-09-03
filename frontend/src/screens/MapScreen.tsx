import React, { useEffect, useMemo, useState } from 'react';
import { api } from '../lib/api';
import MapView from '../components/MapView';

type Point = { id:number; title:string; lat:number; lng:number; category?:string; };

export default function MapScreen(){
  const [points, setPoints] = useState<Point[]>([]);
  const [bbox, setBbox] = useState<[number,number,number,number] | undefined>(undefined);
  const [filter, setFilter] = useState<string|undefined>(undefined);

  useEffect(()=>{
    // Пример bbox для Москвы (если нет гео)
    const fallbackBbox:[number,number,number,number] = [37.2,55.5,37.9,55.95];
    const load = async ()=>{
      const params:any = { limit: 500, bbox: (bbox||fallbackBbox).join(',') };
      if (filter) params.filter = filter;
      const j = await api.points(params);
      setPoints(j.items || []);
    };
    load().catch(console.error);
  },[bbox, filter]);

  // UI для фильтров (минимально)
  const filters = useMemo(()=>[
    {key:undefined, title:'Все'},
    {key:'spot', title:'Споты'},
    {key:'shop', title:'Магазины'},
    {key:'slip', title:'Слипы'},
    {key:'camp', title:'Кемпинги'},
    {key:'catch', title:'Уловы'},
  ],[]);

  return (
    <div className="w-full h-full pt-16 pb-16">
      <div className="absolute top-16 left-0 right-0 z-30 px-4">
        <div className="overflow-x-auto no-scrollbar">
          <div className="inline-flex gap-2 backdrop-blur-xl bg-white/60 border border-white/40 rounded-2xl p-2">
            {filters.map(f=>(
              <button
                key={String(f.key)}
                onClick={()=>setFilter(f.key as any)}
                className={`px-3 py-1 rounded-xl text-sm ${filter===f.key ? 'bg-gradient-to-r from-pink-500 to-fuchsia-600 text-white' : 'bg-white/70 text-gray-800 border border-white/60'}`}
              >
                {f.title}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="absolute inset-0 top-16 bottom-16 z-10">
        <MapView points={points} bbox={bbox}/>
      </div>
    </div>
  );
}
