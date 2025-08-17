import { createTheme } from '@mui/material'
export const buildTheme = (mode:'light'|'dark') => createTheme({
  palette: {
    mode,
    primary: { main: import.meta.env.VITE_UI_PRIMARY || '#0E7490' },
    secondary: { main: import.meta.env.VITE_UI_ACCENT || '#22C55E' },
    background: { default: mode==='light' ? '#eef6f8' : '#0b141a', paper: mode==='light' ? 'rgba(255,255,255,0.7)' : 'rgba(17,25,32,0.5)' }
  },
  shape: { borderRadius: 18 },
  typography: { fontFamily: 'Inter, system-ui, Arial, sans-serif' },
  components: {
    MuiPaper: { styleOverrides: { root: { backdropFilter: `blur(${import.meta.env.VITE_UI_GLASS_BLUR||14}px)` } } },
    MuiAppBar: { styleOverrides: { root: { backdropFilter: `blur(${import.meta.env.VITE_UI_GLASS_BLUR||14}px)` } } }
  }
})
