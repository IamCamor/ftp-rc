import React, { useMemo } from "react";

import Header from "./shims/Header";
import BottomNav from "./shims/BottomNav";

import Feed from "./shims/Feed";
import Map from "./shims/Map";
import AddCatch from "./shims/AddCatch";
import AddPlace from "./shims/AddPlace";
import Alerts from "./shims/Alerts";
import Profile from "./shims/Profile";
import Weather from "./shims/Weather";
import CatchDetail from "./shims/CatchDetail";
import PlaceDetail from "./shims/PlaceDetail";

const routes = {
  "/": Feed,
  "/feed": Feed,
  "/map": Map,
  "/add/catch": AddCatch,
  "/add/place": AddPlace,
  "/alerts": Alerts,
  "/profile": Profile,
  "/weather": Weather,
  "/catch/:id": CatchDetail,
  "/place/:id": PlaceDetail,
} as const;

function usePath() {
  const [path, setPath] = React.useState(() => window.location.pathname + window.location.search);
  React.useEffect(() => {
    const onPop = () => setPath(window.location.pathname + window.location.search);
    window.addEventListener("popstate", onPop);
    return () => window.removeEventListener("popstate", onPop);
  }, []);
  return [path, setPath] as const;
}

function matchRoute(pathname: string) {
  for (const [pattern, Comp] of Object.entries(routes)) {
    if (!pattern.includes(":")) {
      if (pattern === pathname) return { Comp, params: {} as Record<string,string> };
      continue;
    }
    const re = new RegExp("^" + pattern.replace(/:[^/]+/g, "([^/]+)") + "$");
    const m = pathname.match(re);
    if (m) {
      const keys = (pattern.match(/:([^/]+)/g) || []).map(k => k.slice(1));
      const params: Record<string,string> = {};
      keys.forEach((k, i) => params[k] = decodeURIComponent(m[i+1] || ""));
      return { Comp, params };
    }
  }
  return { Comp: Feed, params: {} as Record<string,string> };
}

export default function AppRoot() {
  const [path] = usePath();
  const url = useMemo(() => new URL(path, window.location.origin), [path]);
  const { Comp, params } = matchRoute(url.pathname);
  return (
    <div className="app-shell">
      <Header />
      <main className="app-main">
        <Comp {...params} />
      </main>
      <BottomNav />
    </div>
  );
}
