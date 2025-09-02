// простые «предохранители», чтобы не падать на undefined
export const asString = (v: any) => (v ?? "") + "";
export const safeSlice = (v: any, n: number) => asString(v).slice(0, n);
export const arr = <T = any>(v: any): T[] => (Array.isArray(v) ? (v as T[]) : []);
export const isStr = (v: any): v is string => typeof v === "string";