import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
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
import "./styles/app.css";

function App() {
  return (
    <Router>
      <div className="app-container">
        <Header />
        <main className="app-main">
          <Routes>
            <Route path="/" element={<FeedScreen />} />
            <Route path="/map" element={<MapScreen />} />
            <Route path="/catch/:id" element={<CatchDetailPage />} />
            <Route path="/add-catch" element={<AddCatchPage />} />
            <Route path="/add-place" element={<AddPlacePage />} />
            <Route path="/alerts" element={<NotificationsPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/weather" element={<WeatherPage />} />
            <Route path="/place/:id" element={<PlaceDetailPage />} />
          </Routes>
        </main>
        <BottomNav />
      </div>
    </Router>
  );
}

export default App;
