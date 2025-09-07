import React from 'react';

const MediaGrid: React.FC<{items: Array<{url:string}>}> = ({items}) => {
  const list = Array.isArray(items) ? items : [];
  if (!list.length) return null;
  return (
    <div className="media-grid">
      {list.map((m,i)=>(
        <img key={i} src={m.url} alt={`media-${i}`} loading="lazy" />
      ))}
    </div>
  );
};
export default MediaGrid;
