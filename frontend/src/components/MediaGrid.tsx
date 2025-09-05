import React from "react";

export default function MediaGrid({items}:{items:{url:string,type?:string}[]}) {
  if(!items?.length) return null;
  return (
    <div className="media-grid">
      {items.map((m,idx)=>{
        const isVideo = m.type?.startsWith("video") || /\.(mp4|webm|mov)$/i.test(m.url);
        return (
          <div key={idx} className="media-cell">
            {isVideo ? (
              <video src={m.url} controls playsInline/>
            ) : (
              <img src={m.url} loading="lazy" alt={`media-${idx}`}/>
            )}
          </div>
        );
      })}
    </div>
  );
}
