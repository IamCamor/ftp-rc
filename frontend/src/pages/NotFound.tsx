import React from 'react';
import { Link } from 'react-router-dom';
const NotFound:React.FC = () => (
  <div className="container">
    <div className="glass card" style={{marginTop:16}}>
      <h2>404 — не найдено</h2>
      <p className="subtle">Проверьте адрес или вернитесь на главные разделы.</p>
      <div style={{display:'flex',gap:8}}>
        <Link className="btn" to="/feed"><span className="material-symbols-rounded">home</span>Лента</Link>
        <Link className="btn" to="/map"><span className="material-symbols-rounded">map</span>Карта</Link>
      </div>
    </div>
  </div>
);
export default NotFound;
