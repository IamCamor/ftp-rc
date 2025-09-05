import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from "react-leaflet";
import L, { LatLngBounds } from "leaflet";
import { API } from "../api";
import { Place } from "../types";
import { useNavigate, useSearchParams } from "react-router-dom";
import { CONFIG } from "../config";

// простая утилита дебаунса
function debounce<T extends (...args: any[]) => void>(fn: T, ms: number) {
  let t: any;
  return (...args: Parameters<T>) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}

// Кастомный компонент, слушает перемещения карты и вызывает onBBox
function BBoxListener({ onBBox }: { onBBox: (b: [number, number, number, number]) => void }) {
  const handler = useMemo(
    () =>
      debounce((map: any) => {
        const b: LatLngBounds = map.getBounds();
        const sw = b.getSouthWest();
        const ne = b.getNorthEast();
        onBBox([sw.lng, sw.lat, ne.lng, ne.lat]);
      }, 350),
    [onBBox]
  );

  useMapEvents({
    moveend(map) {
      handler((map as any).target);
    },
    zoomend(map) {
      handler((map as any).target);
    },
  });

  return null;
}

// Фабрика иконок пинов по типу
function makeIconByType(type?: string) {
  const meta = CONFIG.pinTypes[type || ""] || CONFIG.pinTypes.default;
  return L.icon({
    iconUrl: meta.iconUrl,
    iconSize: meta.size,
    iconAnchor: meta.anchor,
    popupAnchor: meta.popupAnchor,
    className: "pin-icon",
  });
}

export default function MapScreen() {
  const [params, setParams] = useSearchParams();
  const [points, setPoints] = useState<Place[]>([]);
  const [loading, setLoading] = useState(false);
  const cacheRef = useRef<{ bboxKey?: string; data: Place[] }>({ data: [] });
  const navigate = useNavigate();

  const initial = useMemo(() => {
    const lat = Number(params.get("lat")) || 55.75;
    const lng = Number(params.get("lng")) || 37.62;
    const z = Number(params.get("z")) || 10;
    return { lat, lng, z };
  }, [params]);

  const fetchPoints = useCallback(
    async (bbox: [number, number, number, number]) => {
      const key = bbox.join(",");
      if (cacheRef.current.bboxKey === key && cacheRef.current.data.length) {
        setPoints(cacheRef.current.data);
        return;
      }
      try {
        setLoading(true);
        const data = await API.points(bbox, 500);
        cacheRef.current = { bboxKey: key, data };
        setPoints(data);
      } catch (e) {
        console.error("points load error", e);
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const onBBox = useCallback(
    (bbox: [number, number, number, number]) => {
      fetchPoints(bbox);
    },
    [fetchPoints]
  );

  // Первичная загрузка: чуть увеличенный bbox вокруг стартовой точки
  useEffect(() => {
    const delta = 0.25;
    const bbox: [number, number, number, number] = [
      initial.lng - delta,
      initial.lat - delta,
      initial.lng + delta,
      initial.lat + delta,
    ];
    fetchPoints(bbox);
  }, [initial, fetchPoints]);

  // Синхроним положение карты в URL (при открытии попапов и кликах это не мешает)
  const onMapMovedPersist = (map: any) => {
    const c = map.getCenter();
    const z = map.getZoom();
    setParams({ lat: String(c.lat.toFixed(5)), lng: String(c.lng.toFixed(5)), z: String(z) }, { replace: true });
  };

  const MapEvents = () => {
    useMapEvents({
      moveend(ev) {
        onMapMovedPersist((ev as any).target);
      },
      zoomend(ev) {
        onMapMovedPersist((ev as any).target);
      },
    });
    return null;
  };

  return (
    <div className="map-page">
      <MapContainer
        center={[initial.lat, initial.lng]}
        zoom={initial.z}
        style={{ height: "100%", width: "100%" }}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution="© OpenStreetMap"
        />
        <BBoxListener onBBox={onBBox} />
        <MapEvents />
        {points.map((p) => (
          <Marker
            key={p.id}
            position={[p.lat, p.lng]}
            icon={makeIconByType(p.type)}
          >
            <Popup>
              <div className="popup-card" onClick={() => navigate(`/place/${p.id}`)}>
                <div className="popup-title">
                  <strong>{p.name}</strong>
                  {p.type && <span className="popup-type">{CONFIG.pinTypes[p.type]?.label || p.type}</span>}
                </div>
                {p.photos?.[0] && (
                  <img
                    src={p.photos[0]}
                    alt={p.name}
                    className="popup-photo"
                  />
                )}
                <div className="popup-link">Перейти к точке →</div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      {loading && <div className="map-loader">Загрузка точек…</div>}
    </div>
  );
}
