import axios, { AxiosHeaders } from 'axios'
const baseURL = import.meta.env.VITE_API_BASE || '/api'
export const http = axios.create({ baseURL })
http.interceptors.request.use(cfg => {
  const token = localStorage.getItem('token')
  if (token) {
    const headers = new AxiosHeaders(cfg.headers)
    headers.set('Authorization', `Bearer ${token}`)
    cfg.headers = headers
  }
  return cfg
})
