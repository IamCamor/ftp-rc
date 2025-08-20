import { Container, CssBaseline, ThemeProvider, createTheme, LinearProgress, Box } from "@mui/material";
import { Routes, Route, NavLink, useLocation } from "react-router-dom";
import { Suspense, useEffect, useState } from "react";
import MapView from "./components/MapView";
import FeedScreen from "./screens/FeedScreen";
import AddPointScreen from "./screens/AddPointScreen";
import AddCatchScreen from "./screens/AddCatchScreen";

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
      <NavLink to="/add/point" style={linkSx as any}>+ Точка</NavLink>
      <NavLink to="/add/catch" style={linkSx as any}>+ Улов</NavLink>
    </div>
  );
}

function GlobalLoader(){
  const loc=useLocation(); const [loading,setLoading]=useState(true);
  useEffect(()=>{ setLoading(true); const t=setTimeout(()=>setLoading(false),250); return ()=>clearTimeout(t); },[loc.pathname]);
  return loading ? <LinearProgress/> : null;
}

export default function App(){
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline/>
      <TopBar/>
      <GlobalLoader/>
      <Container sx={{ py:2, pb:12 }}>
        <Suspense fallback={<Box sx={{my:2}}><LinearProgress/></Box>}>
          <Routes>
            <Route path="/" element={<MapView/>}/>
            <Route path="/map" element={<MapView/>}/>
            <Route path="/feed" element={<FeedScreen/>}/>
            <Route path="/add/point" element={<AddPointScreen/>}/>
            <Route path="/add/catch" element={<AddCatchScreen/>}/>
          </Routes>
        </Suspense>
      </Container>
    </ThemeProvider>
  );
}
