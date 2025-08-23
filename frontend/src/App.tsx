import React,{useEffect,useState} from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import AddCatchPage from "./screens/AddCatchPage";
import AddPlacePage from "./screens/AddPlacePage";
import CatchDetailPage from "./screens/CatchDetailPage";
import BottomNav from "./components/BottomNav";

type Route = {path:string, params:Record<string,string>};

function parseHash():Route{
  const h=location.hash.replace(/^#\/?/,''); // e.g. "catch/12?x=1"
  const [pathPart, qs] = h.split('?');
  const params:Object = Object.fromEntries(new URLSearchParams(qs||'').entries());
  return {path: pathPart||'', params: params as any};
}

export default function App(){
  const [route,setRoute]=useState<Route>(parseHash());
  useEffect(()=>{ const onHash=()=>setRoute(parseHash()); window.addEventListener('hashchange',onHash); return ()=>window.removeEventListener('hashchange',onHash);},[]);

  const activeTab = route.path.startsWith('feed') ? 'feed' : route.path==='' ? 'map' : route.path.startsWith('profile') ? 'profile' : 'map';

  let page:any=null;
  if(route.path==='') page=<MapScreen/>;
  else if(route.path.startsWith('feed')) page=<FeedScreen/>;
  else if(route.path.startsWith('add/catch')) page=<AddCatchPage/>;
  else if(route.path.startsWith('add/place')) page=<AddPlacePage/>;
  else if(route.path.startsWith('catch/')){
    const id=parseInt(route.path.split('/')[1]||'0',10); page=<CatchDetailPage id={id}/>;
  } else page=<MapScreen/>;

  return <div className="w-full h-screen bg-gray-100">
    {page}
    <BottomNav onFab={()=>{ location.hash="#/add/catch"; }} active={activeTab as any} onChange={(t:any)=>{
      if(t==='map') location.hash='#/';
      else if(t==='feed') location.hash='#/feed';
      else if(t==='profile') location.hash='#/profile';
      else location.hash='#/';
    }}/>
  </div>;
}
