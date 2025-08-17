// frontend/src/ui/data/api.ts
import axios from 'axios'
import { mockMapPoints } from '../../mocks/api'

// --- флаги и базовый axios ---
export const useMocks = import.meta.env.VITE_USE_MOCKS === 'true'
const base = import.meta.env.VITE_API_BASE || '/api'
export const http = axios.create({ baseURL: base })

http.interceptors.request.use((cfg) => {
  const t = localStorage.getItem('token')
  if (t) cfg.headers = { ...cfg.headers, Authorization: `Bearer ${t}` }
  return cfg
})

// --- типы ---
export type MapPoint = {
  id: number
  title: string
  description?: string
  lat: number
  lng: number
  type: 'spot' | 'shop' | 'slip' | 'base'
  is_featured: boolean
  visibility: string
}

export type CatchRecord = {
  id: number
  user_id?: number
  lat: number
  lng: number
  species?: string
  length?: number
  weight?: number
  depth?: number
  style?: string
  lure?: string
  tackle?: string
  friend_id?: number | null
  privacy?: 'all' | 'friends' | 'groups' | 'none'
}

// --- локальное хранилище для моков ---
const ADDED_POINTS_KEY = 'ftp_added_points'
const ADDED_CATCHES_KEY = 'ftp_added_catches'

let addedPoints: MapPoint[] = []
let addedCatches: CatchRecord[] = []

try {
  addedPoints = JSON.parse(localStorage.getItem(ADDED_POINTS_KEY) || '[]')
  addedCatches = JSON.parse(localStorage.getItem(ADDED_CATCHES_KEY) || '[]')
} catch {
  addedPoints = []
  addedCatches = []
}

const saveLocal = () => {
  localStorage.setItem(ADDED_POINTS_KEY, JSON.stringify(addedPoints))
  localStorage.setItem(ADDED_CATCHES_KEY, JSON.stringify(addedCatches))
}

// --- auth ---
export async function login(email: string, password: string) {
  const { data } = await http.post('/auth/login', { email, password })
  localStorage.setItem('token', data.token)
  return data
}
export async function register(name: string, email: string, password: string) {
  const { data } = await http.post('/auth/register', { name, email, password })
  localStorage.setItem('token', data.token)
  return data
}
export async function me() {
  const { data } = await http.get('/me')
  return data
}

// --- точки карты ---
export async function fetchMapPoints(): Promise<MapPoint[]> {
  if (useMocks) {
    // моки + локально добавленные
    return [...mockMapPoints, ...addedPoints]
  }
  const { data } = await http.get('/map/points')
  return data
}

// локальное добавление точки (для моков)
export async function addPointLocal(p: Partial<MapPoint>): Promise<MapPoint> {
  // минимальная валидация
  if (typeof p.lat !== 'number' || typeof p.lng !== 'number') {
    throw new Error('lat/lng обязательны для точки')
  }
  const newPoint: MapPoint = {
    id: Date.now(),
    title: p.title || 'Новая точка',
    description: p.description || '',
    lat: p.lat,
    lng: p.lng,
    type: (p.type as any) || 'spot',
    is_featured: !!p.is_featured,
    visibility: p.visibility || 'public'
  }
  addedPoints.push(newPoint)
  saveLocal()
  return newPoint
}

// реальное добавление точки (API)
export async function createMapPoint(p: Omit<MapPoint, 'id'>) {
  const { data } = await http.post('/map/points', p)
  return data
}

// --- уловы ---
export async function addCatchLocal(c: Partial<CatchRecord>): Promise<CatchRecord> {
  if (typeof c.lat !== 'number' || typeof c.lng !== 'number') {
    throw new Error('lat/lng обязательны для улова')
  }
  const rec: CatchRecord = {
    id: Date.now(),
    lat: c.lat,
    lng: c.lng,
    species: c.species || 'Unknown',
    length: c.length,
    weight: c.weight,
    depth: c.depth,
    style: c.style,
    lure: c.lure,
    tackle: c.tackle,
    friend_id: c.friend_id ?? null,
    privacy: c.privacy || 'all'
  }
  addedCatches.push(rec)
  saveLocal()
  return rec
}

export async function createCatch(c: Omit<CatchRecord, 'id'>) {
  const { data } = await http.post('/catches', c)
  return data
}

// --- лента, лайки, комментарии ---
export async function getFeedGlobal() {
  if (useMocks) {
    // простая «заглушка» ленты из локальных уловов
    return addedCatches.map((c) => ({
      id: c.id,
      species: c.species,
      weight: c.weight,
      length: c.length,
      lat: c.lat,
      lng: c.lng,
      likes: 0,
      comments: []
    }))
  }
  const { data } = await http.get('/feed/global')
  return data
}

export async function likeCatch(catchId: number) {
  if (useMocks) return { ok: true, catchId }
  const { data } = await http.post(`/feed/${catchId}/like`)
  return data
}

export async function commentCatch(catchId: number, text: string) {
  if (useMocks) return { ok: true, catchId, text }
  const { data } = await http.post(`/feed/${catchId}/comment`, { text })
  return data
}

// --- админ (пример) ---
export async function adminStats() {
  if (useMocks) return { users: 10, map_points: mockMapPoints.length + addedPoints.length, catches: addedCatches.length }
  const { data } = await http.get('/admin/stats')
  return data
}
