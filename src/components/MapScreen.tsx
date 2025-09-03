import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { fetchMapIcons, fetchMapPoints, MapPoint } from '../api/api';

const TILE_URL = import.meta.env.VITE_OSM_TILES ?? 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const TILE_ATTR = import.meta.env.VITE_OSM_ATTR ?? '&copy; OpenStreetMap contributors';

type IconCfg = string | { url: string; size?: [number, number]; anchor?: [number, number]; popup?: [number, number]; };
type IconConfigPayload = { types: Record<string, IconCfg>; default: IconCfg };

function toLeafletIcon(cfg: IconCfg): L.Icon {
  const base = typeof cfg === 'string' ? { url: cfg } : cfg;
  const size = (base as any).size ?? [32, 32];
  const anchor = (base as any).anchor ?? [size[0] / 2, size[1]];
  const popup = (base as any).popup ?? [0, - Math.max(22, Math.round(size[1] * 0.8))];
  return L.icon({
    iconUrl: (base as any).url,
    iconSize: size as L.PointTuple,
    iconAnchor: anchor as L.PointTuple,
    popupAnchor: popup as L.PointTuple,
  });
}

export default function MapScreen() {
  const mapEl = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    if (!mapEl.current) return;

    const map = L.map(mapEl.current).setView([55.751244, 37.618423], 5);
    mapRef.current = map;

    L.tileLayer(TILE_URL, {
      attribution: TILE_ATTR,
      maxZoom: 19,
    }).addTo(map);

    (async () => {
      try {
        const iconsCfg = (await fetchMapIcons()) as unknown as IconConfigPayload;
        const res = await fetchMapPoints(2000, 0);

        const cache: Record<string, L.Icon> = {};
        const makeIcon = (type: string) => {
          if (cache[type]) return cache[type];
          const cfg: IconCfg = iconsCfg.types[type] ?? iconsCfg.default;
          const icon = toLeafletIcon(cfg);
          cache[type] = icon;
          return icon;
        };

        res.items.forEach((p: MapPoint) => {
          const t = p.highlight ? 'highlight' : p.type;
          const marker = L.marker([p.lat, p.lng], { icon: makeIcon(t) });
          const html = `
            <div>
              <strong>${p.title ?? ''}</strong><br/>
              <small>${p.descr ?? ''}</small><br/>
              <span>Тип: ${p.type}</span>
            </div>
          `;
          marker.bindPopup(html);
          marker.addTo(map);
        });
      } catch (e:any) {
        console.error(e);
        setError('Не удалось загрузить карту/точки');
      }
    })();

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  return (
    <div className="w-full h-[80vh]">
      {error && <div className="p-2 text-red-600">{error}</div>}
      <div ref={mapEl} className="w-full h-full rounded-xl overflow-hidden shadow" />
    </div>
  );
}
