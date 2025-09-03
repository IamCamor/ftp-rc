// src/components/Icon.tsx
import React from "react";

type Props = { name: string; className?: string };
export default function Icon({ name, className }: Props) {
  switch (name) {
    case "map":
      return (<svg className={className} viewBox="0 0 24 24" fill="none"><path d="M3 6l6-3 6 3 6-3v15l-6 3-6-3-6 3V6z" stroke="currentColor" strokeWidth="1.5" /></svg>);
    case "feed":
      return (<svg className={className} viewBox="0 0 24 24" fill="none"><rect x="3" y="4" width="18" height="6" rx="2" stroke="currentColor" strokeWidth="1.5"/><rect x="3" y="12" width="18" height="8" rx="2" stroke="currentColor" strokeWidth="1.5"/></svg>);
    case "bell":
      return (<svg className={className} viewBox="0 0 24 24" fill="none"><path d="M12 3a6 6 0 00-6 6v3.764l-1.447 2.414A1 1 0 005.382 17H18.62a1 1 0 00.828-1.58L18 12.764V9a6 6 0 00-6-6z" stroke="currentColor" strokeWidth="1.5"/><path d="M9 19a3 3 0 006 0" stroke="currentColor" strokeWidth="1.5"/></svg>);
    case "plus":
      return (<svg className={className} viewBox="0 0 24 24" fill="none"><path d="M12 5v14M5 12h14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>);
    case "user":
      return (<svg className={className} viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="currentColor" strokeWidth="1.5"/><path d="M4 20c1.5-3.5 5-5 8-5s6.5 1.5 8 5" stroke="currentColor" strokeWidth="1.5"/></svg>);
    case "search":
      return (<svg className={className} viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="7" stroke="currentColor" strokeWidth="1.5"/><path d="M21 21l-4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>);
    case "weather":
      return (<svg className={className} viewBox="0 0 24 24" fill="none"><circle cx="7" cy="7" r="3" stroke="currentColor" strokeWidth="1.5"/><path d="M7 4V2M7 12v2M4 7H2M12 7h2M10 10l-1 1M10 4l-1-1" stroke="currentColor" strokeWidth="1.5"/></svg>);
    default:
      return <span className={className}>★</span>;
  }
}
