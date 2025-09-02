
import React, { useMemo, useState } from "react";
import MapScreen from "../screens/MapScreen";
import FeedScreen from "../screens/FeedScreen";
import ProfileScreen from "../screens/ProfileScreen";
import AuthScreen from "../screens/AuthScreen";
import WeatherScreen from "../screens/WeatherScreen";
import LeaderboardScreen from "../screens/LeaderboardScreen";
import CommentsScreen from "../screens/CommentsScreen";
import CatchDetailScreen from "../screens/CatchDetailScreen";
import BottomNav from "../components/BottomNav";
import { useAuthState } from "../data/auth";

type Tab = "map" | "feed" | "weather" | "leaderboard" | "profile";
type FeedTab = "all" | "friends" | "near" | "species";

export default function App() {
  const [tab, setTab] = useState<Tab>("map");
  const [feedTab, setFeedTab] = useState<FeedTab>("all");
  const { isAuthed } = useAuthState();
  const [commentsForCatchId, setCommentsForCatchId] = useState<number | null>(null);
  const [detailsCatchId, setDetailsCatchId] = useState<number | null>(null);

  const needAuth = useMemo(
    () => (tab === "profile" || feedTab === "friends") && !isAuthed,
    [tab, feedTab, isAuthed]
  );

  const onFab = () => {
    if (tab === "map") {
      window.dispatchEvent(new CustomEvent("open:add-point"));
    } else if (tab === "feed") {
      window.dispatchEvent(new CustomEvent("open:add-catch"));
    } else {
      alert("Действие появится позже");
    }
  };

  // external events from other UI
  React.useEffect(() => {
    const openCatch = (e: any) => setDetailsCatchId(e.detail?.id ?? null);
    window.addEventListener("open:catch", openCatch as any);
    return () => window.removeEventListener("open:catch", openCatch as any);
  }, []);

  return (
    <div className="relative w-full h-screen bg-[rgb(245,246,248)]">
      {tab === "map" && (
        <MapScreen
          onOpenCatch={(id: number) => setDetailsCatchId(id)}
          onOpenSpecies={(sp: string) => {
            setTab("feed");
            setFeedTab("species");
            window.dispatchEvent(new CustomEvent("feed:set-species", { detail: sp }));
          }}
        />
      )}

      {tab === "feed" && (
        <FeedScreen
          tab={feedTab}
          onChangeTab={setFeedTab}
          onOpenCatch={(id: number) => setDetailsCatchId(id)}
          onOpenComments={(id: number) => setCommentsForCatchId(id)}
          onOpenProfile={(uid: number) => {
            setTab("profile");
            window.dispatchEvent(new CustomEvent("profile:open", { detail: uid }));
          }}
        />
      )}

      {tab === "weather" && <WeatherScreen />}
      {tab === "leaderboard" && (
        <LeaderboardScreen
          onOpenUser={(uid: number) => {
            setTab("profile");
            window.dispatchEvent(new CustomEvent("profile:open", { detail: uid }));
          }}
        />
      )}
      {tab === "profile" && <ProfileScreen />}

      <BottomNav
        onFab={onFab}
        active={tab}
        onChange={(t: Tab) => setTab(t)}
        items={[
          { key: "map", label: "Карта", icon: "map" },
          { key: "feed", label: "Лента", icon: "feed" },
          { key: "weather", label: "Погода", icon: "weather" },
          { key: "leaderboard", label: "Топ", icon: "trophy" },
          { key: "profile", label: "Профиль", icon: "user" },
        ]}
      />

      {needAuth && <AuthScreen onClose={() => setTab("map")} />}

      {commentsForCatchId !== null && (
        <CommentsScreen
          catchId={commentsForCatchId}
          onClose={() => setCommentsForCatchId(null)}
        />
      )}

      {detailsCatchId !== null && (
        <CatchDetailScreen
          catchId={detailsCatchId}
          onClose={() => setDetailsCatchId(null)}
          onOpenComments={() => {
            if (detailsCatchId !== null) setCommentsForCatchId(detailsCatchId);
          }}
          onOpenPlace={(placeId?: number, bbox?: [number, number, number, number]) => {
            setTab("map");
            window.dispatchEvent(new CustomEvent("map:focus", { detail: { placeId, bbox } }));
          }}
          onOpenSpecies={(species: string) => {
            setTab("feed");
            setFeedTab("species");
            window.dispatchEvent(new CustomEvent("feed:set-species", { detail: species }));
          }}
          onOpenProfile={(uid: number) => {
            setTab("profile");
            window.dispatchEvent(new CustomEvent("profile:open", { detail: uid }));
          }}
        />
      )}
    </div>
  );
}
