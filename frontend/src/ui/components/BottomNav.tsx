import { BottomNavigation, BottomNavigationAction, Paper } from "@mui/material";
import MapIcon from "@mui/icons-material/Map";
import DynamicFeedIcon from "@mui/icons-material/DynamicFeed";
import EventIcon from "@mui/icons-material/Event";
import GroupsIcon from "@mui/icons-material/Groups";
import { useLocation, useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";

export default function BottomNav(){
  const nav=useNavigate(); const loc=useLocation(); const [value,setValue]=useState(0);
  useEffect(()=>{ if(loc.pathname.startsWith("/map")) setValue(0);
    else if(loc.pathname.startsWith("/feed")) setValue(1);
    else if(loc.pathname.startsWith("/events")) setValue(2);
    else if(loc.pathname.startsWith("/clubs")) setValue(3);
    else setValue(-1); },[loc.pathname]);
  return (
    <Paper sx={{position:"fixed",bottom:12,left:12,right:12,borderRadius:4}} elevation={6} className="glass">
      <BottomNavigation value={value} onChange={(_,v)=>setValue(v)} showLabels>
        <BottomNavigationAction label="Карта" icon={<MapIcon/>} onClick={()=>nav("/map")}/>
        <BottomNavigationAction label="Лента" icon={<DynamicFeedIcon/>} onClick={()=>nav("/feed")}/>
        <BottomNavigationAction label="События" icon={<EventIcon/>} onClick={()=>nav("/events")}/>
        <BottomNavigationAction label="Клубы" icon={<GroupsIcon/>} onClick={()=>nav("/clubs")}/>
      </BottomNavigation>
    </Paper>
  );
}
