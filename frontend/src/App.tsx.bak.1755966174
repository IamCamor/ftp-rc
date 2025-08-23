import React, { useMemo, useState } from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import ProfileScreen from "./screens/ProfileScreen";
import AuthScreen from "./screens/AuthScreen";
import BottomNav from "./components/BottomNav";
import { useAuthState } from "./data/auth";
type Tab="map"|"feed"|"alerts"|"profile";

export default function App(){
  const [tab,setTab]=useState<Tab>("map"); const {isAuthed}=useAuthState();
  const needAuth=useMemo(()=> (tab==="feed"||tab==="profile") && !isAuthed, [tab,isAuthed]);
  const onFab=()=>{ if(tab==="map") alert("Форма добавления точки"); else if(tab==="feed") alert("Форма публикации"); else alert("Действие появится позже"); };
  return (
    <div className="relative w-full h-screen bg-gray-100">
      {tab==="map" && <MapScreen/>}
      {tab==="feed" && <FeedScreen/>}
      {tab==="alerts" && <div className="flex items-center justify-center w-full h-full text-gray-600">Уведомления скоро будут</div>}
      {tab==="profile" && <ProfileScreen/>}
      <BottomNav onFab={onFab} active={tab} onChange={setTab as any}/>
      {needAuth && <AuthScreen onClose={()=>setTab("map")}/>}
    </div>
  );
}
