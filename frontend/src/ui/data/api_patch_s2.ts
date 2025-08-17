import { http } from './api'
export async function getFeedGlobal(){ const { data } = await http.get('/feed/global'); return data }
export async function getFeedLocal(lat:number,lng:number,km:number=50){ const { data } = await http.get('/feed/local?near='+[lat,lng,km].join(',')); return data }
export async function getFeedFollow(){ const { data } = await http.get('/feed/follow'); return data }
export async function likeCatch(catchId:number){ const { data } = await http.post(`/feed/${catchId}/like`); return data }
export async function unlikeCatch(catchId:number){ const { data } = await http.post(`/feed/${catchId}/unlike`); return data }
export async function commentCatch(catchId:number, text:string){ const { data } = await http.post(`/feed/${catchId}/comment`, { text }); return data }

export async function moderationList(){ const { data } = await http.get('/admin/moderation'); return data }
export async function moderationApprove(id:number){ const { data } = await http.post(`/admin/moderation/${id}/approve`); return data }
export async function moderationReject(id:number){ const { data } = await http.post(`/admin/moderation/${id}/reject`); return data }
