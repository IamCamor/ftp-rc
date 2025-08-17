export type MapPoint = { id:number; title:string; description?:string; lat:number; lng:number; type:'spot'|'shop'|'slip'|'base'|'catch'; is_featured:boolean; visibility:string; species?:string; weight?:number; length?:number }
const rnd=(a:number,b:number)=>Math.random()*(b-a)+a
const types = ['spot','shop','slip','base','catch'] as const
export const mockMapPoints: MapPoint[] = Array.from({length:120}).map((_,i)=>{
  const t = types[Math.floor(Math.random()*types.length)]
  return { id:i+1, title:`${t.toUpperCase()} #${i+1}`, description:'Demo', lat:55.7+rnd(-0.5,0.5), lng:37.6+rnd(-0.5,0.5), type:t as any, is_featured:Math.random()<0.1, visibility:'public',
    species: t==='catch'? (Math.random()<0.5?'Pike':'Carp'): undefined, weight: t==='catch'? Number(rnd(0.5,8).toFixed(1)) : undefined, length: t==='catch'? Math.round(rnd(20,100)) : undefined
  }
})
