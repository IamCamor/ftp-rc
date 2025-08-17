// src/ui/App.tsx
import { useMemo, useState } from "react";
import { Routes, Route, Link } from "react-router-dom";
import {
  AppBar, Toolbar, Typography, Button, Container, Box, CssBaseline,
  ThemeProvider, createTheme, BottomNavigation, BottomNavigationAction, Paper
} from "@mui/material";
import MapIcon from "@mui/icons-material/Map";
import PublicIcon from "@mui/icons-material/Public";
import AddLocationAltIcon from "@mui/icons-material/AddLocationAlt";
import GroupsIcon from "@mui/icons-material/Groups";
import EventIcon from "@mui/icons-material/Event";
import ChatIcon from "@mui/icons-material/Chat";
import NotificationsIcon from "@mui/icons-material/Notifications";
import StarIcon from "@mui/icons-material/Star";

import MapScreen from "./screens/MapScreen";
import AddCatchScreen from "./screens/AddCatchScreen";
import EventsScreen from "./screens/EventsScreen";
import ClubsScreen from "./screens/ClubsScreen";
import SubscribeScreen from "./screens/SubscribeScreen";
import ChatsScreen from "./screens/ChatsScreen";
import NotificationsScreen from "./screens/NotificationsScreen";

const FeedScreen = () => <Container sx={{ py: 3 }}><Typography variant="h5">Лента</Typography></Container>;

function buildTheme(mode: "light" | "dark") {
  return createTheme({ palette: { mode }, shape: { borderRadius: 14 } });
}

export default function App() {
  const [mode, setMode] = useState<"light" | "dark">("light");
  const theme = useMemo(() => buildTheme(mode), [mode]);
  const [tab, setTab] = useState(0);

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ pb: 9 }}>
        <AppBar position="sticky" color="primary" elevation={6}>
          <Toolbar>
            <Typography variant="h6" sx={{ flexGrow: 1 }}>
              <Link to="/" style={{ textDecoration: "none", color: "inherit" }}>FishTrackPro</Link>
            </Typography>
            <Button color="inherit" component={Link} to="/subscribe" startIcon={<StarIcon />}>Pro</Button>
            <Button color="inherit" onClick={() => setMode(mode === "light" ? "dark" : "light")}>
              {mode === "light" ? "Тёмная" : "Светлая"}
            </Button>
          </Toolbar>
        </AppBar>

        <Container sx={{ py: 2 }}>
          <Routes>
            <Route path="/" element={<FeedScreen />} />
            <Route path="/map" element={<MapScreen />} />
            <Route path="/add" element={<AddCatchScreen />} />
            <Route path="/events" element={<EventsScreen />} />
            <Route path="/clubs" element={<ClubsScreen />} />
            <Route path="/chats" element={<ChatsScreen />} />
            <Route path="/notifications" element={<NotificationsScreen />} />
            <Route path="/subscribe" element={<SubscribeScreen />} />
          </Routes>
        </Container>

        <Paper sx={{ position: "fixed", left: 0, right: 0, bottom: 0 }} elevation={8}>
          <BottomNavigation value={tab} onChange={(_e, v) => setTab(v)} showLabels>
            <BottomNavigationAction component={Link} to="/" label="Лента" icon={<PublicIcon />} />
            <BottomNavigationAction component={Link} to="/map" label="Карта" icon={<MapIcon />} />
            <BottomNavigationAction component={Link} to="/add" label="Добавить" icon={<AddLocationAltIcon />} />
            <BottomNavigationAction component={Link} to="/clubs" label="Клубы" icon={<GroupsIcon />} />
            <BottomNavigationAction component={Link} to="/events" label="События" icon={<EventIcon />} />
            <BottomNavigationAction component={Link} to="/chats" label="Чаты" icon={<ChatIcon />} />
            <BottomNavigationAction component={Link} to="/notifications" label="Уведомления" icon={<NotificationsIcon />} />
          </BottomNavigation>
        </Paper>
      </Box>
    </ThemeProvider>
  );
}
