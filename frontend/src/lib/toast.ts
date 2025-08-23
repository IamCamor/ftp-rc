export function toast(msg: string) {
  const el = document.createElement('div');
  el.textContent = msg;
  el.className = 'fixed left-1/2 -translate-x-1/2 bottom-24 px-4 py-2 rounded-full bg-black/70 text-white text-sm z-[1000]';
  document.body.appendChild(el);
  setTimeout(()=> el.remove(), 2200);
}
