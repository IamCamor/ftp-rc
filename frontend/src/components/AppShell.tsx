import React from 'react';
import Header from './Header';
import BottomNav from './BottomNav';
import '../styles/app.css';

export default function AppShell({children}:{children:React.ReactNode}){
  return (
    <div className="app-root">
      <Header />
      <main className="app-main">{children}</main>
      <BottomNav />
    </div>
  );
}
