let injected = false;

export function ensureMaterialSymbols() {
  if (injected || typeof document === 'undefined') return;
  const id = 'material-symbols-rounded-link';
  if (document.getElementById(id)) { injected = true; return; }
  const link = document.createElement('link');
  link.id = id;
  link.rel = 'stylesheet';
  // порядок осей: FILL,wght,GRAD,opsz – строго алфавитно
  link.href = 'https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:FILL,wght,GRAD,opsz@0,400,0,24';
  document.head.appendChild(link);
  injected = true;
}
