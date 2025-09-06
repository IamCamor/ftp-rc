import React, { useMemo, useState, useEffect, useCallback } from "react";

// Компоненты-шапка/навигация — импорт как namespace с fallback
import * as HeaderModule from "./components/Header";
import * as BottomNavModule from "./components/BottomNav";

// Страницы — также через namespace + fallback (default или именованный)
import * as FeedModule from "./pages/FeedScreen";
import * as MapModule from "./pages/MapScreen";
import * as CatchModule from "./pages/CatchDetailPage";
import * as AddCatchModule from "./pages/AddCatchPage";
import * as AddPlaceModule from "./pages/AddPlacePage";
import * as AlertsModule from "./pages/NotificationsPage";
import * as ProfileModule from "./pages/ProfilePage";
import * as WeatherModule from "./pages/WeatherPage";
import * as PlaceModule from "./pages/PlaceDetailPage";

// Fallback-экспорт для компонентов
const Header: React.FC<any> =
  (HeaderModule as any).default ?? (HeaderModule as any).Header ?? (() => null);
const BottomNav: React.FC<any> =
  (BottomNavModule as any).default ?? (BottomNavModule as any).BottomNav ?? (() => null);

// Fallback-экспорт для страниц
const FeedScreen: React.FC =
  (FeedModule as any).default ?? (FeedModule as any).FeedScreen ?? (() => null);
const MapScreen: React.FC =
  (MapModule as any).default ?? (MapModule as any).MapScreen ?? (() => null);
const AddCatchPage: React.FC =
  (AddCatchModule as any).default ?? (AddCatchModule as any).AddCatchPage ?? (() => null);
const AddPlacePage: React.FC =
  (AddPlaceModule as any).default ?? (AddPlaceModule as any).AddPlacePage ?? (() => null);
const NotificationsPage: React.FC =
  (AlertsModule as any).default ?? (AlertsModule as any).NotificationsPage ?? (() => null);
const ProfilePage: React.FC =
  (ProfileModule as any).default ?? (ProfileModule as any).ProfilePage ?? (() => null);
const WeatherPage: React.FC =
  (WeatherModule as any).default ?? (WeatherModule as any).WeatherPage ?? (() => null);

// Страницы с параметрами
const CatchDetailWrap: React.FC<{ id: string }> = ({ id }) => {
  const Cmp: React.FC<any> =
    (CatchModule as any).default ?? (CatchModule as any).CatchDetailPage ?? (() => null);
  return <Cmp id={id} />;
};

const PlaceDetailWrap: React.FC<{ id: string }> = ({ id }) => {
  const Cmp: React.FC<any> =
    (PlaceModule as any).default ?? (PlaceModule as any).PlaceDetailPage ?? (() => null);
  return <Cmp id={id} />;
};

// Простой роутер на History API
type RouteMatch =
  | { name: "feed" }
  | { name: "map" }
  | { name: "add-catch" }
  | { name: "add-place" }
  | { name: "alerts" }
  | { name: "profile" }
  | { name: "weather" }
  | { name: "catch"; id: string }
  | { name: "place"; id: string }
  | { name: "unknown" };

function parseRoute(pathname: string): RouteMatch {
  const p = (pathname || "/").replace(/\/+$/, "") || "/";
  if (p === "/" || p === "/feed") return { name: "feed" };
  if (p === "/map") return { name: "map" };
  if (p === "/add-catch") return { name: "add-catch" };
  if (p === "/add-place") return { name: "add-place" };
  if (p === "/alerts") return { name: "alerts" };
  if (p === "/profile") return { name: "profile" };
  if (p === "/weather") return { name: "weather" };
  const c = p.match(/^\/catch\/([^/]+)$/);
  if (c) return { name: "catch", id: c[1] };
  const pl = p.match(/^\/place\/([^/]+)$/);
  if (pl) return { name: "place", id: pl[1] };
  return { name: "unknown" };
}

function useRouter() {
  const [path, setPath] = useState<string>(window.location.pathname + window.location.search);
  useEffect(() => {
    const onPop = () => setPath(window.location.pathname + window.location.search);
    window.addEventListener("popstate", onPop);
    return () => window.removeEventListener("popstate", onPop);
  }, []);
  const navigate = useCallback((to: string) => {
    if (to !== window.location.pathname + window.location.search) {
      window.history.pushState({}, "", to);
      setPath(to);
      window.dispatchEvent(new Event("route:change"));
    }
  }, []);
  const route = useMemo(() => parseRoute((path || "/").split("?")[0]), [path]);
  return { route, navigate };
}

const AppRoot: React.FC = () => {
  const { route, navigate } = useRouter();

  const appStyle: React.CSSProperties = {
    minHeight: "100dvh",
    background:
      "radial-gradient(1200px 800px at 10% 10%, rgba(255,255,255,0.15), transparent 60%), " +
      "radial-gradient(1000px 700px at 90% 20%, rgba(255,255,255,0.12), transparent 60%), " +
      "linear-gradient(135deg, rgba(40,60,90,0.65), rgba(10,20,30,0.65))",
    backdropFilter: "blur(8px)",
    WebkitBackdropFilter: "blur(8px)",
  };
  const shellStyle: React.CSSProperties = { maxWidth: 900, margin: "0 auto", paddingBottom: 72 };

  const go = (to: string) => navigate(to);

  let content: React.ReactNode = null;
  switch (route.name) {
    case "feed": content = <FeedScreen />; break;
    case "map": content = <MapScreen />; break;
    case "add-catch": content = <AddCatchPage />; break;
    case "add-place": content = <AddPlacePage />; break;
    case "alerts": content = <NotificationsPage />; break;
    case "profile": content = <ProfilePage />; break;
    case "weather": content = <WeatherPage />; break;
    case "catch": content = <CatchDetailWrap id={route.id} />; break;
    case "place": content = <PlaceDetailWrap id={route.id} />; break;
    default:
      content = (
        <div style={{ padding: 24 }}>
          <h2>Страница не найдена</h2>
          <p><a href="/feed" onClick={(e) => { e.preventDefault(); go("/feed"); }}>На ленту</a></p>
        </div>
      );
  }

  return (
    <div style={appStyle}>
      <Header onNavigate={go} />
      <main style={shellStyle}>{content}</main>
      <BottomNav onNavigate={go} />
    </div>
  );
};

export default AppRoot;
