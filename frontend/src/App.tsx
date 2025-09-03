import React, { useEffect, useMemo, useState } from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import NotificationsPage from "./screens/NotificationsPage";
import ProfilePage from "./screens/ProfilePage";
import BottomNav from "./components/BottomNav";

type Tab = "map"|"feed"|"alerts"|"profile";

function routeToTab(hash: string): Tab {
  const key = hash.replace(/^#\//,'').split(/[?#]/)[0];
  if (key === "feed") return "feed";
  if (key === "alerts") return "alerts";
  if (key === "profile") return "profile";
  return "map";
}

export default function App(){
  const [tab, setTab] = useState<Tab>(routeToTab(location.hash || "#/map"));
  useEffect(()=> {
    const onHash = () => setTab(routeToTab(location.hash || "#/map"));
    window.addEventListener("hashchange", onHash);
    return () => window.removeEventListener("hashchange", onHash);
  },[]);

  useEffect(()=> {
    const target = tab === "map" ? "#/map" : tab === "feed" ? "#/feed" : tab === "alerts" ? "#/alerts" : "#/profile";
    if (location.hash !== target) location.hash = target;
  }, [tab]);

  const onFab = () => {
    if (tab === "map") location.hash = "#/add-place";
    else if (tab === "feed") location.hash = "#/add-catch";
    else alert("Скоро тут появится действие");
  };

  return (
    <div className="relative w-full h-screen bg-gray-50">
      {tab==="map" && <MapScreen/>}
      {tab==="feed" && <FeedScreen/>}
      {tab==="alerts" && <NotificationsPage/>}
      {tab==="profile" && <ProfilePage/>}

      <BottomNav active={tab} onChange={setTab} onFab={onFab}/>
    </div>
  );
}
