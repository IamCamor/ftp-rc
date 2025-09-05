import React from "react";
import { useNavigate } from "react-router-dom";
import { Place } from "../types";
import MediaGrid from "./MediaGrid";

export default function PointPinCard({ place }: { place: Place }) {
  const navigate = useNavigate();
  return (
    <div className="pin-card" onClick={() => navigate(`/place/${place.id}`)}>
      <h3>{place.name}</h3>
      <MediaGrid photos={place.photos} />
    </div>
  );
}
