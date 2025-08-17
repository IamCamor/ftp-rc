import React from 'react'
import ReactDOM from 'react-dom/client'
import { ThemeProvider, createTheme, CssBaseline } from '@mui/material'
import App from './ui/App'
import './ui/i18n'

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: { main: import.meta.
      env.VITE_UI_PRIMARY || '#0E7490' },
    secondary: { main: import.meta.env.VITE_UI_ACCENT || '#22C55E' }
  },
  shape: { borderRadius: 16 }
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <App />
    </ThemeProvider>
  </React.StrictMode>
)
