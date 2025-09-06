import React from 'react';
import { Link } from 'react-router-dom';

const NotFound: React.FC = () => {
  return (
    <div className="container">
      <div className="glass card" style={{padding:20, marginTop:20}}>
        <h2>Страница не найдена (404)</h2>
        <p className="subtle">Похоже, такой страницы нет. Вернёмся на главную?</p>
        <div style={{display:'flex', gap:8}}>
          <Link className="btn" to="/feed"><span className="icon">home</span> Лента</Link>
          <Link className="btn" to="/map"><span className="icon">map</span> Карта</Link>
        </div>
      </div>
    </div>
  );
};
export default NotFound;
