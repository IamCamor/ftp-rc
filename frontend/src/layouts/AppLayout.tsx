import React from 'react';
import Header from '../components/Header';
import BottomNav from '../components/BottomNav';

type Props = {
  children: React.ReactNode;
};

const AppLayout: React.FC<Props> = ({ children }) => {
  return (
    <div>
      <Header />
      <main className="main-wrap">
        {children}
      </main>
      <BottomNav />
    </div>
  );
};

export default AppLayout;
