import axios from 'axios'
const baseURL = import.meta.env.VITE_API_BASE || '/api'
export const http = axios.create({ baseURL })
http.interceptors.request.use(cfg => {
  const token = localStorage.getItem('token')
  if (token) cfg.headers = { ...(cfg.headers||{}), Authorization: `Bearer ${token}` }
  return cfg
})
