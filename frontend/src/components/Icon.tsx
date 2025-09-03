import React from 'react';

type Props = { name: string; className?: string; strokeWidth?: number };
export default function Icon({ name, className = 'w-6 h-6', strokeWidth=1.8 }: Props) {
  const common = { fill: 'none', stroke: 'currentColor', strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round' } as any;
  switch (name) {
    case 'map': return <svg className={className} viewBox="0 0 24 24"><path {...common} d="M9 18l-6 3V6l6-3 6 3 6-3v15l-6 3-6-3zM9 3v15M15 6v15"/></svg>;
    case 'feed': return <svg className={className} viewBox="0 0 24 24"><rect {...common} x="3" y="4" width="18" height="16" rx="3"/><path {...common} d="M3 9h18"/></svg>;
    case 'weather': return <svg className={className} viewBox="0 0 24 24"><path {...common} d="M12 3v2m0 14v2m9-9h-2M5 12H3m15.36-6.36l-1.42 1.42M6.06 17.94l-1.42 1.42M18 16a4 4 0 10-6-3.46A5 5 0 106 16"/></svg>;
    case 'profile': return <svg className={className} viewBox="0 0 24 24"><path {...common} d="M12 12a5 5 0 1 0-5-5 5 5 0 0 0 5 5zM3 21a9 9 0 0 1 18 0"/></svg>;
    case 'trophy': return <svg className={className} viewBox="0 0 24 24"><path {...common} d="M8 21h8M12 17v4M5 4h14v4a7 7 0 0 1-14 0zM5 8H4a3 3 0 0 1 0-6h1M19 8h1a3 3 0 0 0 0-6h-1"/></svg>;
    case 'friends': return <svg className={className} viewBox="0 0 24 24"><path {...common} d="M16 11a4 4 0 1 0-4-4 4 4 0 0 0 4 4zM8 13a4 4 0 1 0-4-4M22 21a6 6 0 0 0-12 0M10 21a6 6 0 0 0-12 0"/></svg>;
    case 'bell': return <svg className={className} viewBox="0 0 24 24"><path {...common} d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5M9 21a3 3 0 0 0 6 0"/></svg>;
    default: return <span className={className}/>;
  }
}
