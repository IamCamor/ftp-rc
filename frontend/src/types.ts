export interface User {
  id: number;
  name: string;
  avatar?: string;
  bonuses?: number;
}

export interface CatchItem {
  id: number;
  user: User;
  species: string;
  lat?: number;
  lng?: number;
  length?: number;
  weight?: number;
  style?: string;
  lure?: string;
  tackle?: string;
  notes?: string;
  photo_url?: string;
  created_at?: string;
}

export interface Place {
  id: number;
  name: string;
  type?: string; // spot|shop|base|catch|...
  lat: number;
  lng: number;
  photos?: string[];
  description?: string;
}
