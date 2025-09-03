import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import BottomNav from "./components/BottomNav";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import NotificationsPage from "./screens/NotificationsPage";
import ProfilePage from "./screens/ProfilePage";
import FriendsPage from "./screens/FriendsPage";
import RatingsPage from "./screens/RatingsPage";
import SettingsPage from "./screens/SettingsPage";
import MyCatchesPage from "./screens/MyCatchesPage";
import AddCatchPage from "./screens/AddCatchPage";
import AddPlacePage from "./screens/AddPlacePage";
import CatchDetailPage from "./screens/CatchDetailPage";
import PlaceDetailPage from "./screens/PlaceDetailPage";
import WeatherPage from "./screens/WeatherPage";

export default function App(){
  return (
    <div className="relative w-full h-screen bg-gray-50">
      <Routes>
        <Route path="/" element={<Navigate to="/map" replace/>} />
        <Route path="/map" element={<MapScreen/>} />
        <Route path="/feed" element={<FeedScreen/>} />
        <Route path="/alerts" element={<NotificationsPage/>} />
        <Route path="/profile" element={<ProfilePage/>} />
        <Route path="/friends" element={<FriendsPage/>} />
        <Route path="/ratings" element={<RatingsPage/>} />
        <Route path="/settings" element={<SettingsPage/>} />
        <Route path="/my-catches" element={<MyCatchesPage/>} />
        <Route path="/add-catch" element={<AddCatchPage/>} />
        <Route path="/add-place" element={<AddPlacePage/>} />
        <Route path="/catch/:id" element={<CatchDetailPage/>} />
        <Route path="/place/:id" element={<PlaceDetailPage/>} />
        <Route path="/weather" element={<WeatherPage/>} />
        <Route path="*" element={<Navigate to="/map" replace/>}/>
      </Routes>

      <BottomNav/>
    </div>
  );
}
