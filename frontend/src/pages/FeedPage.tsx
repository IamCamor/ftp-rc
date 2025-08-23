// frontend/src/pages/FeedPage.tsx
import React, { useEffect, useMemo, useState } from 'react';
import { fetchFeed, FeedItem } from '../api/feed';

type Tab = 'global'|'local'|'follow';

export default function FeedPage() {
  const [tab, setTab] = useState<Tab>('global');
  const [items, setItems] = useState<FeedItem[]>([]);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [loading, setLoading] = useState(false);
  const [loc, setLoc] = useState<{lat:number, lng:number} | null>(null);

  useEffect(() => {
    if (tab !== 'local') return;
    navigator.geolocation.getCurrentPosition(
      (pos) => setLoc({lat: pos.coords.latitude, lng: pos.coords.longitude}),
      ()   => setLoc({lat: 55.75, lng: 37.62}), // дефолт Москва
      { enableHighAccuracy: false, timeout: 4000 }
    );
  }, [tab]);

  useEffect(() => {
    setItems([]); setPage(1); setHasMore(true);
    void loadPage(1);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, loc?.lat, loc?.lng]);

  async function loadPage(nextPage:number) {
    if (loading || !hasMore) return;
    setLoading(true);
    try {
      const data = await fetchFeed({
        scope: tab,
        lat: tab==='local' ? loc?.lat : undefined,
        lng: tab==='local' ? loc?.lng : undefined,
        page: nextPage,
        per: 10
      });
      if (nextPage === 1) setItems(data.items);
      else setItems(prev => [...prev, ...data.items]);
      setHasMore(!!data.meta?.next);
      setPage(nextPage);
    } catch (e) {
      console.warn(e);
    }
    setLoading(false);
  }

  const FeedCard = useMemo(() => (props: any) => import('../components/FeedCard').then(m => <m.default {...props}/>), []);

  return (
    <div className="min-h-dvh bg-gradient-to-b from-zinc-50 to-zinc-100 dark:from-zinc-900 dark:to-black">
      {/* Top bar */}
      <div className="sticky top-0 z-20 p-3">
        <div className="flex items-center gap-2 px-3 py-2 border shadow-xl backdrop-blur-xl bg-white/60 dark:bg-zinc-800/50 border-white/40 dark:border-white/10 rounded-2xl">
          <input
            type="search" placeholder="Поиск по ленте… (в разработке)"
            className="flex-1 bg-transparent outline-none text-zinc-800 dark:text-zinc-100 placeholder:text-zinc-400"
            disabled
          />
        </div>
        {/* Tabs */}
        <div className="flex gap-2 mt-3 overflow-x-auto no-scrollbar">
          {[
            {key:'global', label:'Global'},
            {key:'local',  label:'Local'},
            {key:'follow', label:'Follow'},
          ].map(t => (
            <button key={t.key}
              onClick={()=>setTab(t.key as Tab)}
              className={`px-4 py-2 rounded-full border transition whitespace-nowrap
                ${tab===t.key ? 'bg-gradient-to-r from-pink-400 to-rose-400 text-white border-transparent' :
                'bg-white/60 dark:bg-zinc-800/50 text-zinc-700 dark:text-zinc-200 border-white/40 dark:border-white/10'}`}>
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {/* Feed list */}
      <div className="p-3 space-y-4">
        {items.map(it => (
          <React.Suspense key={it.id} fallback={<SkeletonCard/>}>
            <FeedCard item={it} />
          </React.Suspense>
        ))}
        {loading && <SkeletonCard/>}
        {!loading && hasMore && (
          <div className="flex justify-center">
            <button onClick={()=>loadPage(page+1)}
              className="px-5 py-2 border rounded-full bg-white/70 dark:bg-zinc-800/60 border-white/40 dark:border-white/10">
              Показать ещё
            </button>
          </div>
        )}
        {!loading && items.length===0 && (
          <div className="py-10 text-center text-zinc-400">Пока нет публикаций</div>
        )}
      </div>
    </div>
  );
}

function SkeletonCard() {
  return (
    <div className="border shadow-xl animate-pulse backdrop-blur-xl bg-white/50 dark:bg-zinc-800/50 rounded-2xl border-white/40 dark:border-white/10">
      <div className="flex items-center gap-3 p-3">
        <div className="rounded-full w-9 h-9 bg-zinc-200 dark:bg-zinc-700"/>
        <div className="w-40 h-3 rounded bg-zinc-200 dark:bg-zinc-700"/>
      </div>
      <div className="w-full h-48 bg-zinc-200 dark:bg-zinc-700"/>
      <div className="p-4">
        <div className="w-3/4 h-3 rounded bg-zinc-200 dark:bg-zinc-700"/>
      </div>
    </div>
  );
}