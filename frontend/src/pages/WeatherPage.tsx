import React, { useMemo } from 'react';
import { getWeatherFavs } from '../api';
import { Link } from 'react-router-dom';

const WeatherPage:React.FC = () => {
  const favs = useMemo(() => getWeatherFavs(), []);
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Погода</h2>
        {!favs.length && <div className="subtle">Добавьте точку на карте (клик по карте → «В погоду»), и она появится здесь.</div>}
        <ul>
          {favs.map((f,i) => (
            <li key={i}>
              {f.name} — <Link to={`/map`}>на карте</Link>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};
export default WeatherPage;
