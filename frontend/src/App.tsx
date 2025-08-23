import React, { useMemo, useState } from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import ProfileScreen from "./screens/ProfileScreen";
import AuthScreen from "./screens/AuthScreen";
import BottomNav from "./components/BottomNav";
import AddCatchScreen from "./screens/AddCatchScreen";
import AddPlaceScreen from "./screens/AddPlaceScreen";
import Modal from "./components/Modal";
import { useAuthState } from "./data/auth";

type Tab="map"|"feed"|"alerts"|"profile";
type FormKind = null | "catch" | "place" | "chooser";

export default function App(){
  const [tab,setTab]=useState<Tab>("map");
  const {isAuthed}=useAuthState?.() ?? {isAuthed:false};
  const needAuth=useMemo(()=> (tab==="feed"||tab==="profile") && !isAuthed, [tab,isAuthed]);
  const [form,setForm]=useState<FormKind>(null);

  const onFab=()=>{
    // Показываем селектор: Добавить улов / Добавить место
    setForm("chooser");
  };

  const closeAll = ()=> setForm(null);

  return (
    <div className="relative w-full h-screen bg-gray-100">
      {tab==="map" && <MapScreen/>}
      {tab==="feed" && <FeedScreen/>}
      {tab==="alerts" && <div className="flex items-center justify-center w-full h-full text-gray-600">Уведомления скоро будут</div>}
      {tab==="profile" && <ProfileScreen/>}

      <BottomNav onFab={onFab} active={tab} onChange={setTab as any}/>

      {needAuth && <AuthScreen onClose={()=>setTab("map")}/>}

      {/* Выбор действия FAB */}
      <Modal open={form==="chooser"} onClose={closeAll} title="Что добавить?">
        <div className="grid sm:grid-cols-2 gap-3">
          <button className="btn-primary" onClick={()=>setForm("catch")}>🎣 Улов</button>
          <button className="btn-secondary" onClick={()=>setForm("place")}>📍 Место</button>
        </div>
      </Modal>

      {/* Форма улова */}
      <Modal open={form==="catch"} onClose={closeAll} title="Добавить улов">
        <AddCatchScreen onDone={closeAll}/>
      </Modal>

      {/* Форма места */}
      <Modal open={form==="place"} onClose={closeAll} title="Добавить место">
        <AddPlaceScreen onDone={closeAll}/>
      </Modal>
    </div>
  );
}
