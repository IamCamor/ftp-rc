import React,{useEffect,useMemo,useState} from 'react';
import './styles/app.css';
import Header from './components/Header';
import BottomNav from './components/BottomNav';

import MapScreen from './pages/MapScreen';
import FeedScreen from './pages/FeedScreen';
import CatchDetailPage from './pages/CatchDetailPage';
import AddCatchPage from './pages/AddCatchPage';
import AddPlacePage from './pages/AddPlacePage';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import WeatherPage from './pages/WeatherPage';
import PlaceDetailPage from './pages/PlaceDetailPage';

function useRouter(){
  const [path,setPath]=useState<string>(location.pathname || '/');
  useEffect(()=>{
    (window as any).navigate = (p:string)=>{
      if(p===path) return;
      history.pushState({},'',p);
      setPath(p);
      // авто-скролл вверх
      window.scrollTo({top:0,behavior:'instant' as any});
    };
    const onPop=()=>setPath(location.pathname || '/');
    window.addEventListener('popstate', onPop);
    return ()=>window.removeEventListener('popstate', onPop);
  },[path]);
  return path;
}

export default function App(){
  const path = useRouter();

  const page = useMemo(()=>{
    // деталка
    const catchMatch = path.match(/^\/catch\/(\d+)/);
    if(catchMatch) return <CatchDetailPage id={catchMatch[1]} />;

    const placeMatch = path.match(/^\/place\/(\d+)/);
    if(placeMatch) return <PlaceDetailPage id={placeMatch[1]} />;

    switch(true){
      case path==='/':
      case path.startsWith('/map'): return <MapScreen/>;
      case path.startsWith('/feed'): return <FeedScreen/>;
      case path.startsWith('/add-catch'): return <AddCatchPage/>;
      case path.startsWith('/add-place'): return <AddPlacePage/>;
      case path.startsWith('/alerts'): return <NotificationsPage/>;
      case path.startsWith('/profile'): return <ProfilePage/>;
      case path.startsWith('/weather'): return <WeatherPage/>;
      default: return <div className="container" style={{padding:20}}>Страница не найдена</div>;
    }
  },[path]);

  // какая вкладка активна для нижнего меню
  const activeTab = useMemo(()=>{
    if(path.startsWith('/feed')) return '/feed';
    if(path.startsWith('/alerts')) return '/alerts';
    if(path.startsWith('/profile')) return '/profile';
    return '/map';
  },[path]);

  return (
    <div>
      <Header bonuses={0}/>
      {page}
      <BottomNav active={activeTab}/>
    </div>
  );
}
