export type LatLng = { lat:number; lng:number };

export type Point = {
  id: number|string;
  name?: string;
  type?: "spot"|"catch"|"shop"|"base"|string;
  lat: number;
  lng: number;
  photos?: string[];
  description?: string;
};

export type FeedItem = {
  id: number;
  user_id: number;
  user_name?: string;
  user_avatar?: string;
  lat?: number;
  lng?: number;
  species?: string;
  length?: number|string;
  weight?: number|string;
  method?: string;
  bait?: string;
  gear?: string;
  caption?: string;
  media_url?: string;
  created_at?: string;
  likes_count?: number;
  comments_count?: number;
  liked_by_me?: 0|1|boolean;
};

export type CatchRecord = FeedItem & {
  media_urls?: string[];
  weather?: any;
  privacy?: "all"|"friends"|"private";
  caught_at?: string;
};

export type NotificationItem = {
  id: number;
  title: string;
  body?: string;
  link?: string;
  created_at?: string;
  read?: boolean;
};

export type ProfileMe = {
  id: number;
  name: string;
  avatar?: string;
  photo_url?: string;
  email?: string;
  stats?: { catches?: number; friends?: number; points?: number };
};
