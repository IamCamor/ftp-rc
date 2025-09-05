import React, { useEffect, useState } from 'react';
import { api } from '../api';

type Profile = {
  id: number|string;
  name: string;
  avatar?: string;
  points?: number;
};

export default function ProfilePage() {
  const [me, setMe] = useState<Profile | null>(null);
  const [error, setError] = useState('');

  useEffect(()=>{
    (async ()=>{
      try {
        setError('');
        const data: any = await api.me();
        setMe({
          id: data?.id ?? 'me',
          name: data?.name ?? 'Гость',
          avatar: data?.avatar ?? data?.photo_url ?? '',
          points: data?.points ?? data?.bonus ?? 0,
        });
      } catch (e:any) {
        setError(e?.message || 'Недоступно');
        setMe(null);
      }
    })();
  },[]);

  return (
    <div className="p-3">
      <div className="glass card p-3 mb-3">
        <strong>Профиль</strong>
      </div>

      {error && (
        <div className="text-sm text-amber-600 mb-3">
          {error.includes('401') ? 'Требуется вход' : error}
        </div>
      )}

      {me ? (
        <div className="glass-light p-4 flex items-center gap-3">
          <img
            src={me.avatar || '/default-avatar.png'}
            alt="avatar"
            width="64" height="64"
            style="border-radius:50%; object-fit:cover"
          />
          <div>
            <div className="text-lg font-medium">{me.name}</div>
            <div className="opacity-75 text-sm">Баллы: {me.points ?? 0}</div>
          </div>
        </div>
      ) : (
        !error && <div className="opacity-70 text-sm">Загрузка…</div>
      )}
    </div>
  );
}
