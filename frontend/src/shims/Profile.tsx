/* Auto-shim: подхватывает default, именованный или любой похожий на React-компонент */
import * as M from '../pages/ProfilePage';

const pickFromNamespace = (mod: any, prefer: string) => {
  if (!mod || typeof mod !== 'object') return null;
  // 1) default, если есть
  if (mod.default) return mod.default;
  // 2) предпочитаемый именованный
  if (prefer && mod[prefer]) return mod[prefer];
  // 3) любой элемент, похожий на React-компонент
  const cand = Object.values(mod).find((v: any) =>
    typeof v === 'function' ||
    (v && typeof v === 'object' && (v as any).$$typeof) // React element type symbol
  );
  return cand || null;
};

const C: any = pickFromNamespace(M as any, 'ProfilePage') || (() => null);
export default C;
