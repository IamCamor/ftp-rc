import React from 'react';
import { ASSETS } from '../config/assets';

type Props = { name: string; photo?: string; right?: React.ReactNode; onClick?: ()=>void };
export default function UserCard({name, photo, right, onClick}: Props){
  return (
    <div onClick={onClick} className="flex items-center justify-between px-3 py-2 rounded-2xl bg-white/60 backdrop-blur border border-white/40 shadow-sm">
      <div className="flex items-center gap-3">
        <img src={photo || ASSETS.avatarPlaceholder} className="w-10 h-10 rounded-full object-cover" />
        <div className="text-sm font-medium">{name}</div>
      </div>
      <div>{right}</div>
    </div>
  );
}
