import React from 'react';
const AddPlacePage:React.FC = () => {
  const params = new URLSearchParams(location.search);
  const lat = params.get('lat'); const lng = params.get('lng');
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Добавить место</h2>
        {lat && lng && <p className="subtle">Координаты: {lat}, {lng}</p>}
        <p className="subtle">Форма в разработке — заполним по ТЗ (название, описание, фото и т.д.).</p>
      </div>
    </div>
  );
};
export default AddPlacePage;
