import { createTheme } from "@mui/material"

export function buildTheme(mode: "light" | "dark", cfg?: any) {
  return createTheme({
    palette: {
      mode,
      primary: { main: cfg?.brand?.primaryColor || "#1976d2" },
      secondary: { main: cfg?.brand?.accentColor || "#ff9800" },
    },
    components: {
      MuiPaper: {
        styleOverrides: {
          root: {
            background: `rgba(255,255,255,${cfg?.glass?.opacity ?? 0.7})`,
            backdropFilter: `blur(${cfg?.glass?.blur ?? "8px"})`,
          },
        },
      },
      MuiCard: {
        styleOverrides: {
          root: {
            borderRadius: "16px",
            boxShadow: "0 4px 20px rgba(0,0,0,0.1)",
          },
        },
      },
    },
  })
}
