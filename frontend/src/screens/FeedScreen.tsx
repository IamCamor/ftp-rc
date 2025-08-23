import { useEffect, useState } from "react";

type Post = {
  id: number;
  user: { name: string; avatar?: string };
  text: string;
  photo?: string;
  created_at: string;
};

export default function FeedScreen() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("https://api.fishtrackpro.ru/api/v1/feed?limit=20")
      .then(r => r.json())
      .then(data => {
        setPosts(data.items || []);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex items-center justify-center h-full">Загрузка...</div>;

  return (
    <div className="h-full pb-16 overflow-y-auto">
      {posts.map(post => (
        <div key={post.id} className="p-4 border-b border-gray-200 bg-white/70 backdrop-blur-sm">
          <div className="flex items-center gap-3 mb-2">
            <img
              src={post.user.avatar || "/avatar-placeholder.png"}
              alt={post.user.name}
              className="w-10 h-10 rounded-full"
            />
            <div>
              <div className="font-semibold">{post.user.name}</div>
              <div className="text-xs text-gray-500">
                {new Date(post.created_at).toLocaleString()}
              </div>
            </div>
          </div>
          <div className="mb-2 text-gray-800">{post.text}</div>
          {post.photo && (
            <img
              src={post.photo}
              alt="post"
              className="object-cover w-full rounded-xl"
            />
          )}
        </div>
      ))}
      {posts.length === 0 && <div className="p-4 text-center text-gray-500">Нет публикаций</div>}
    </div>
  );
}