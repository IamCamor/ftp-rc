import React from 'react';
import { getWeatherFavs } from '../api';

const WeatherPage: React.FC = () => {
  const favs = getWeatherFavs();
  const list = Array.isArray(favs) ? favs : [];

  return (
    <div className="container">
      <h2 className="h2">Погода</h2>
      {list.length === 0 ? (
        <div className="muted glass card">Пока ни одной избранной точки. Нажмите по карте, чтобы добавить.</div>
      ) : (
        <ul className="grid" style={{listStyle:'none', padding:0}}>
          {list.map((p, idx) => (
            <li key={idx} className="card glass">
              <div style={{fontWeight:600}}>{p.title || `Точка (${p.lat.toFixed(4)}, ${p.lng.toFixed(4)})`}</div>
              <div className="muted">температура: — / ветер: — (добавим, когда появится серверный маршрут)</div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

export default WeatherPage;
