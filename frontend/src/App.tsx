// src/App.tsx
import React, { useMemo, useState, useEffect } from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import ProfileScreen from "./screens/ProfileScreen";
import WeatherPage from "./screens/WeatherPage";
import AddCatchPage from "./screens/AddCatchPage";
import AddPlacePage from "./screens/AddPlacePage";
import CatchDetailPage from "./screens/CatchDetailPage";
import BottomNav from "./components/BottomNav";

type Tab = "map" | "feed" | "alerts" | "profile";
function useHash() {
  const [hash, setHash] = useState(window.location.hash || "#/map");
  useEffect(() => {
    const on = () => setHash(window.location.hash || "#/map");
    window.addEventListener("hashchange", on);
    return () => window.removeEventListener("hashchange", on);
  }, []);
  return [hash, (h:string)=>{ window.location.hash = h; setHash(h);} ] as const;
}

export default function App() {
  const [hash] = useHash();
  const [tab, setTab] = useState<Tab>("map");

  useEffect(() => {
    if (hash.startsWith("#/feed")) setTab("feed");
    else if (hash.startsWith("#/profile")) setTab("profile");
    else setTab("map");
  }, [hash]);

  const onFab = () => {
    if (hash.startsWith("#/feed")) window.location.hash = "#/add-catch";
    else window.location.hash = "#/add-place";
  };

  const main = () => {
    if (hash === "#/map") return <MapScreen />;
    if (hash === "#/feed") return <FeedScreen />;
    if (hash === "#/profile") return <ProfileScreen />;
    if (hash.startsWith("#/weather")) return <WeatherPage />;
    if (hash.startsWith("#/add-catch")) return <AddCatchPage />;
    if (hash.startsWith("#/add-place")) return <AddPlacePage />;
    if (hash.startsWith("#/catch/")) return <CatchDetailPage id={hash.split("/")[2]} />;
    return <MapScreen />;
  };

  return (
    <div className="relative w-full h-screen bg-gray-100">
      {main()}
      <BottomNav onFab={onFab} active={tab} onChange={(t)=>{ setTab(t); window.location.hash = `#/${t}`; }} />
    </div>
  );
}
