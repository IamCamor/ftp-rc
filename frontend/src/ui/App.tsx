import { Container, CssBaseline, ThemeProvider, createTheme } from "@mui/material";
import { Routes, Route, NavLink } from "react-router-dom";
import MapView from "./components/MapView";
import FeedScreen from "./screens/FeedScreen";
import AddCatchScreen from "./screens/AddCatchScreen";
import AddPointScreen from "./screens/AddPointScreen";
import EventsScreen from "./screens/EventsScreen";
import BottomNav from "./components/BottomNav";

const theme = createTheme({
  palette:{ mode:"dark", primary:{ main:"#57B0E6" }, secondary:{ main:"#1DE9B6" } },
  shape:{ borderRadius:16 }
});

function TopBar(){
  const linkSx = { color:"#fff", textDecoration:"none", marginRight:16 };
  return (
    <div style={{position:"sticky",top:0,zIndex:10,padding:"12px 16px"}} className="glass">
      <NavLink to="/map" style={linkSx as any}>Карта</NavLink>
      <NavLink to="/feed" style={linkSx as any}>Лента</NavLink>
      <NavLink to="/events" style={linkSx as any}>События</NavLink>
    </div>
  );
}

export default function App(){
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline/>
      <TopBar/>
      <Container sx={{ py:2, pb:12 }}>
        <Routes>
          <Route path="/" element={<MapView/>}/>
          <Route path="/map" element={<MapView/>}/>
          <Route path="/feed" element={<FeedScreen/>}/>
          <Route path="/events" element={<EventsScreen/>}/>
          <Route path="/add/catch" element={<AddCatchScreen/>}/>
          <Route path="/add/point" element={<AddPointScreen/>}/>
        </Routes>
      </Container>
      <BottomNav/>
    </ThemeProvider>
  );
}
