import React from 'react';
import Header from './components/Header';
import BottomNav from './components/BottomNav';
import FeedScreen from './pages/FeedScreen';
import MapScreen from './pages/MapScreen';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import './styles/app.css';

function RouterSwitch(){
  const path = typeof window !== 'undefined' ? window.location.pathname : '/feed';

  if (path === '/' || path === '/feed') return <FeedScreen />;
  if (path.startsWith('/map')) return <MapScreen />;
  if (path.startsWith('/alerts')) return <NotificationsPage />;
  if (path.startsWith('/profile')) return <ProfilePage />;

  // простые-заглушки — чтобы сборка не падала
  if (path.startsWith('/add-catch')) return <div className="p-3"><div className="card">Форма добавления улова (в разработке)</div></div>;
  if (path.startsWith('/add-place')) return <div className="p-3"><div className="card">Форма добавления места (в разработке)</div></div>;
  if (path.startsWith('/weather')) return <div className="p-3"><div className="card">Погода (в разработке)</div></div>;
  if (path.startsWith('/catch/')) return <div className="p-3"><div className="card">Карточка улова (в разработке)</div></div>;
  if (path.startsWith('/place/')) return <div className="p-3"><div className="card">Карточка места (в разработке)</div></div>;

  return <div className="p-3"><div className="card">Страница не найдена</div></div>;
}

export default function App(){
  return (
    <div>
      <Header />
      <RouterSwitch />
      <BottomNav />
    </div>
  );
}
