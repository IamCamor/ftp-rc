import React, { useEffect, useState } from 'react';
import config from '../config';
import Icon from './Icon';

type Banner = {
  id: number | string;
  image_url?: string;
  link_url?: string;
  title?: string;
};

type Props = {
  slot: string;           // идентификатор баннерного места
  className?: string;
  limit?: number;         // сколько баннеров показывать (по умолчанию 1)
};

const BannerSlot: React.FC<Props> = ({ slot, className, limit = 1 }) => {
  const [banners, setBanners] = useState<Banner[] | null>(null);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    let aborted = false;

    async function load() {
      try {
        setErr(null);
        // Берём базу из конфига. Если в конфиге есть api.v1Base — используем его, иначе api.base
        const apiBase =
          (config as any)?.api?.v1Base ??
          (config as any)?.apiBase ??
          (config as any)?.api?.base ??
          '';

        // Прямой запрос без зависимости от src/api.ts
        const url = `${apiBase}/banners?slot=${encodeURIComponent(slot)}&limit=${encodeURIComponent(
          String(limit)
        )}`;

        const res = await fetch(url, {
          method: 'GET',
          credentials: 'include',
          headers: {
            'Accept': 'application/json'
          }
        });

        if (!res.ok) {
          throw new Error(`HTTP ${res.status}`);
        }

        const data = await res.json().catch(() => ({}));
        // Поддержим оба формата: {items:[...]} или сразу [...]
        const items: Banner[] = Array.isArray(data) ? data : (Array.isArray(data?.items) ? data.items : []);

        if (!aborted) {
          setBanners(items);
        }
      } catch (e: any) {
        if (!aborted) {
          setErr(e?.message || 'Failed to load banners');
          setBanners([]);
        }
      }
    }

    load();

    return () => {
      aborted = true;
    };
  }, [slot, limit]);

  const fallbackImg =
    (config as any)?.banners?.fallbackImage ||
    (config as any)?.images?.bannerFallback ||
    '';

  if (err) {
    return (
      <div className={`glass rounded-xl p-3 ${className || ''}`}>
        <div className="flex items-center gap-2 text-red-500">
          <Icon name="error" />
          <span>Ошибка загрузки баннеров: {err}</span>
        </div>
      </div>
    );
  }

  if (!banners) {
    return (
      <div className={`glass rounded-xl p-3 ${className || ''}`}>
        <div className="flex items-center gap-2 opacity-70">
          <Icon name="hourglass_top" />
          <span>Загрузка…</span>
        </div>
      </div>
    );
  }

  if (banners.length === 0) {
    // Пусто — покажем заглушку, чтобы слот не “прыгнул”
    return (
      <div className={`glass rounded-xl p-3 ${className || ''}`}>
        <div className="flex items-center gap-2 opacity-60">
          <Icon name="image" />
          <span>Баннеров нет</span>
        </div>
      </div>
    );
  }

  return (
    <div className={`w-full ${className || ''}`}>
      {banners.slice(0, limit).map((b) => {
        const img = b.image_url || fallbackImg;
        const content = (
          <div
            className="glass rounded-2xl overflow-hidden border border-white/10"
            style={{
              backdropFilter: 'blur(12px)'
            }}
          >
            {img ? (
              <img
                src={img}
                alt={b.title || 'banner'}
                className="w-full h-auto block"
                loading="lazy"
              />
            ) : (
              <div className="p-4 flex items-center gap-2">
                <Icon name="image" />
                <span>{b.title || 'Рекламный баннер'}</span>
              </div>
            )}
          </div>
        );

        return (
          <div key={String(b.id)} className="mb-3 last:mb-0">
            {b.link_url ? (
              <a href={b.link_url} target="_blank" rel="noopener noreferrer">
                {content}
              </a>
            ) : (
              content
            )}
          </div>
        );
      })}
    </div>
  );
};

export default BannerSlot;
