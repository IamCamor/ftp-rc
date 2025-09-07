import React from 'react';
import Header from '../components/Header';
import BottomNav from '../components/BottomNav';

const AppLayout: React.FC<React.PropsWithChildren> = ({ children }) => {
  return (
    <div className="app-shell">
      <Header />
      <main className="app-content">{children}</main>
      <BottomNav />
    </div>
  );
};

export default AppLayout;
