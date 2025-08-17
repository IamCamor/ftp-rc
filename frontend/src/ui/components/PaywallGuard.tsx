import React from 'react'

type Props = { children: React.ReactNode; require?: 'pro' | boolean }

export default function PaywallGuard({ children }: Props){
  return <>{children}</>
}
