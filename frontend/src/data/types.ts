export type PointType = "spot"|"shop"|"slip"|"camp"|"catch"|string;

export type Point = {
  id: number;
  title: string;
  lat: number;
  lng: number;
  type?: PointType;
  description?: string|null;
  address?: string|null;
  tags?: string[]|null;
};
