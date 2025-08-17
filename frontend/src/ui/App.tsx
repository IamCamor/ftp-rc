import { BrowserRouter, Routes, Route } from "react-router-dom"
import { CssBaseline, ThemeProvider } from "@mui/material"
import { useMemo, useState } from "react"
import { buildTheme } from "./theme"
import { uiConfig } from "../config/ui"
import MapScreen from "./screens/MapScreen"
import AddCatchScreen from "./screens/AddCatchScreen"
import ClubsScreen from "./screens/ClubsScreen"
import EventsScreen from "./screens/EventsScreen"
import ChatsScreen from "./screens/ChatsScreen"
import NotificationsScreen from "./screens/NotificationsScreen"
import BottomNav from "./components/BottomNav"

export default function App() {
  const [mode] = useState<"light" | "dark">("light")
  const theme = useMemo(() => buildTheme(mode, uiConfig), [mode])

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<MapScreen />} />
          <Route path="/add-catch" element={<AddCatchScreen />} />
          <Route path="/clubs" element={<ClubsScreen />} />
          <Route path="/events" element={<EventsScreen />} />
          <Route path="/chats" element={<ChatsScreen />} />
          <Route path="/notifications" element={<NotificationsScreen />} />
        </Routes>
        <BottomNav />
      </BrowserRouter>
    </ThemeProvider>
  )
}
