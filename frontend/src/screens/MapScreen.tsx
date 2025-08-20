import React, { useState } from "react";
import SearchBar from "../components/SearchBar";
import FilterChips, { FilterName } from "../components/FilterChips";
import MapView from "../components/MapView";
export default function MapScreen(){
  const [search,setSearch]=useState(""); const [filter,setFilter]=useState<FilterName>("Все");
  return (
    <div className="relative w-full h-full bg-gray-100">
      <SearchBar value={search} onChange={setSearch}/>
      <FilterChips active={filter} onChange={setFilter}/>
      <div className="w-full h-full"><MapView filter={filter} q={search}/></div>
    </div>
  );
}
