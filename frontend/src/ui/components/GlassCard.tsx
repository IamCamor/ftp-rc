import React from 'react';

type Props = React.PropsWithChildren<{style?: React.CSSProperties}>;

export default function GlassCard({ children, style }: Props){
  return (
    <div style={{
      background: 'rgba(255,255,255,0.08)',
      backdropFilter: 'blur(12px) saturate(140%)',
      WebkitBackdropFilter: 'blur(12px) saturate(140%)',
      border: '1px solid rgba(255,255,255,0.15)',
      borderRadius: 16,
      padding: 16,
      ...style
    }}>{children}</div>
  );
}
