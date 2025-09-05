import React from "react";

export default function MediaGrid({ photos }: { photos?: string[] }) {
  if (!photos?.length) return null;
  return (
    <div className="media-grid">
      {photos.map((src, i) => (
        <img key={i} src={src} alt={`media-${i}`} />
      ))}
    </div>
  );
}
