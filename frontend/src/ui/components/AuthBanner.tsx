import React from 'react'
import { Alert, Button, Stack, TextField } from '@mui/material'
import { login, me } from '../data/api'
export default function AuthBanner(){
  const [email, setEmail] = React.useState('demo@fishtrackpro.ru')
  const [password, setPassword] = React.useState('password')
  const [user, setUser] = React.useState<any>(null)
  const [error, setError] = React.useState('')
  React.useEffect(()=>{
    const t = localStorage.getItem('token')
    if (t) me().then(setUser).catch(()=>localStorage.removeItem('token'))
  }, [])
  if (user) return null
  const onLogin = async () => {
    try {
      setError('')
      await login(email, password)
      const u = await me()
      setUser(u)
      location.reload()
    } catch (e:any) {
      setError(e?.response?.data?.message || 'Ошибка входа')
    }
  }
  return (
    <Alert severity="info" sx={{ mb: 2 }} action={<Button color="inherit" size="small" onClick={onLogin}>Войти</Button>}>
      <Stack direction="row" spacing={1} sx={{ mt: 1 }}>
        <TextField size="small" label="Email" value={email} onChange={e=>setEmail(e.target.value)} />
        <TextField size="small" label="Пароль" type="password" value={password} onChange={e=>setPassword(e.target.value)} />
      </Stack>
      {error && <div style={{ marginTop: 8, color: 'crimson' }}>{error}</div>}
    </Alert>
  )
}
