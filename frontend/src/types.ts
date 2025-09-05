export type Id = number | string;

export interface Media {
  url: string;
  type: 'image' | 'video';
}

export interface Point {
  id: Id;
  title: string;
  type: 'shop'|'slip'|'camp'|'catch'|'spot'|string;
  lat: number; lng: number;
  photo?: { url: string } | null;
  photos?: Media[];
}

export interface CatchItem {
  id: Id;
  user_id: Id;
  user_name: string;
  user_avatar?: string;
  species?: string|null;
  length?: number|null;
  weight?: number|null;
  method?: string|null;
  bait?: string|null;
  gear?: string|null;
  caption?: string|null;
  media_url?: string|null;
  created_at: string;
  lat?: number; lng?: number;
  place_id?: Id|null;
  likes_count?: number;
  comments_count?: number;
  liked_by_me?: 0|1;
}

export interface WeatherNow {
  temp_c?: number|null;
  wind_ms?: number|null;
  source?: string;
}

export interface NotificationItem {
  id: Id;
  title: string;
  body?: string;
  created_at: string;
  read?: boolean;
}

export interface ProfileMe {
  id: Id;
  name: string;
  avatar?: string;
  bonuses?: number;
}
