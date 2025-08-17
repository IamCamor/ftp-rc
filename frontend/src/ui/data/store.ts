import { create } from 'zustand'
export type Point = { id:number; title:string; lat:number; lng:number; type:string; is_featured:boolean }
type State = { points: Point[]; add:(p:Point)=>void }
export const useMapStore = create<State>((set)=>({ points: [], add: (p)=> set(s=>({ points:[...s.points, p] })) }))
