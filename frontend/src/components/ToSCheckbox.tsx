import React from "react";

export default function ToSCheckbox({checked,onChange}:{checked:boolean;onChange:(v:boolean)=>void}) {
  const terms = (import.meta as any).env?.VITE_LEGAL_TERMS_URL || "#";
  const privacy = (import.meta as any).env?.VITE_LEGAL_PRIVACY_URL || "#";
  return (
    <label className="flex items-start gap-2 text-sm text-gray-700">
      <input type="checkbox" className="mt-1" checked={checked} onChange={e=>onChange(e.target.checked)} />
      <span>
        Я принимаю {" "}
        <a className="underline" href={terms} target="_blank" rel="noreferrer">Пользовательское соглашение</a>
        {" "} и {" "}
        <a className="underline" href={privacy} target="_blank" rel="noreferrer">Политику конфиденциальности</a>.
      </span>
    </label>
  );
}
