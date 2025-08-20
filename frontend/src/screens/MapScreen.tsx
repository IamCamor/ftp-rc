import React, { useState } from "react";
import SearchBar from "../components/SearchBar";
import FilterChips, { FilterName } from "../components/FilterChips";
import BottomNav from "../components/BottomNav";
import MapView from "../components/MapView";

export default function MapScreen() {
  const [tab, setTab] = useState<"feed"|"map"|"alerts"|"profile">("map");
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<FilterName>("Все");
  const onFab = () => { alert("Открыть форму добавления точки"); };

  return (
    <div className="relative w-full h-screen bg-gray-100">
      <SearchBar value={search} onChange={setSearch} />
      <FilterChips active={filter} onChange={setFilter} />
      <div className="w-full h-full">
        <MapView filter={filter} q={search} />
      </div>
      <BottomNav onFab={onFab} active={tab} onChange={setTab} />
    </div>
  );
}
