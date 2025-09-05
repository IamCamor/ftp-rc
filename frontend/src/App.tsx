import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import Header from "./components/Header";
import BottomNav from "./components/BottomNav";

import FeedScreen from "./pages/FeedScreen";
import MapScreen from "./pages/MapScreen";
import CatchDetailPage from "./pages/CatchDetailPage";
import AddCatchPage from "./pages/AddCatchPage";
import AddPlacePage from "./pages/AddPlacePage";
import NotificationsPage from "./pages/NotificationsPage";
import ProfilePage from "./pages/ProfilePage";
import WeatherPage from "./pages/WeatherPage";
import PlaceDetailPage from "./pages/PlaceDetailPage";

export default function App(){
  // points в хедере можно подтянуть из профиля, здесь заглушка
  const [points] = React.useState<number>(0);

  return (
    <div className="app">
      <Header points={points}/>
      <Routes>
        <Route path="/" element={<Navigate to="/map" replace/>} />
        <Route path="/map" element={<MapScreen/>} />
        <Route path="/feed" element={<FeedScreen/>} />
        <Route path="/catch/:id" element={<CatchDetailPage/>} />
        <Route path="/add-catch" element={<AddCatchPage/>} />
        <Route path="/add-place" element={<AddPlacePage/>} />
        <Route path="/alerts" element={<NotificationsPage/>} />
        <Route path="/profile" element={<ProfilePage/>} />
        <Route path="/weather" element={<WeatherPage/>} />
        <Route path="/place/:id" element={<PlaceDetailPage/>} />
        {/* запасной роут */}
        <Route path="*" element={<Navigate to="/map" replace/>}/>
      </Routes>
      <BottomNav/>
    </div>
  );
}
