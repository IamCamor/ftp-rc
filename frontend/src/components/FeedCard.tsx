// frontend/src/components/FeedCard.tsx
import React, { useState } from 'react';
import { FeedItem, getComments, like, unlike, addComment } from '../api/feed';

export default function FeedCard({ item }: { item: FeedItem }) {
  const [liked, setLiked] = useState<boolean>(!!item.liked_by_me);
  const [likes, setLikes] = useState<number>(item.likes_count ?? 0);
  const [commentsOpen, setCommentsOpen] = useState(false);
  const [comments, setComments] = useState<Array<any>>([]);
  const [loadingComments, setLoadingComments] = useState(false);
  const [commentText, setCommentText] = useState('');

  const toggleLike = async () => {
    try {
      if (liked) { await unlike(item.id); setLiked(false); setLikes(Math.max(0, likes-1)); }
      else       { await like(item.id);   setLiked(true);  setLikes(likes+1); }
    } catch (e) {
      console.warn(e);
      alert('Требуется вход для лайков');
    }
  };

  const openComments = async () => {
    setCommentsOpen(true);
    setLoadingComments(true);
    try {
      const data = await getComments(item.id);
      setComments(data.items || []);
    } catch (e) { console.warn(e); }
    setLoadingComments(false);
  };

  const sendComment = async () => {
    if (!commentText.trim()) return;
    try {
      await addComment(item.id, commentText.trim());
      setCommentText('');
      const data = await getComments(item.id);
      setComments(data.items || []);
    } catch (e) {
      console.warn(e);
      alert('Требуется вход для комментариев');
    }
  };

  return (
    <div className="overflow-hidden border shadow-xl backdrop-blur-xl bg-white/50 dark:bg-zinc-800/50 rounded-2xl border-white/40 dark:border-white/10">
      {/* Header */}
      <div className="flex items-center gap-3 p-3">
        <img src={item.user_avatar || '/avatar.svg'} alt="" className="object-cover rounded-full w-9 h-9 ring-1 ring-white/50" />
        <div className="flex-1 min-w-0">
          <div className="text-sm font-medium truncate text-zinc-900 dark:text-zinc-100">{item.user_name || 'Рыбак'}</div>
          <div className="text-xs text-zinc-500">{item.created_at ? new Date(item.created_at).toLocaleString() : ''}</div>
        </div>
      </div>

      {/* Media */}
      {item.media_url && (
        <img src={item.media_url} alt="" className="w-full max-h-[60vh] object-cover" />
      )}

      {/* Body */}
      <div className="p-4 space-y-2">
        <div className="text-zinc-900 dark:text-zinc-100">
          {item.caption || 'Без описания'}
        </div>
        <div className="flex flex-wrap gap-3 text-xs text-zinc-500">
          {item.species && <span>🐟 {item.species}</span>}
          {item.size_cm!=null && <span>📏 {item.size_cm} см</span>}
          {item.weight_g!=null && <span>⚖️ {Math.round(item.weight_g/100)/10} кг</span>}
          {item.method && <span>🎣 {item.method}</span>}
          {item.bait && <span>🪱 {item.bait}</span>}
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-4 px-4 pb-4">
        <button onClick={toggleLike}
          className={`px-3 py-1.5 rounded-full border transition
            ${liked ? 'border-pink-400 bg-pink-100/60 text-pink-700' : 'border-white/40 bg-white/40 text-zinc-700 dark:text-zinc-200'}`}>
          ❤ {likes}
        </button>
        <button onClick={openComments}
          className="px-3 py-1.5 rounded-full border border-white/40 bg-white/40 text-zinc-700 dark:text-zinc-200">
          💬 {item.comments_count ?? 0}
        </button>
      </div>

      {/* Comments sheet */}
      {commentsOpen && (
        <div className="px-4 pb-4">
          {loadingComments ? (
            <div className="text-sm text-zinc-400">Загрузка комментариев…</div>
          ) : (
            <div className="pr-2 space-y-3 overflow-auto max-h-64">
              {comments.map(c => (
                <div key={c.id} className="flex items-start gap-2">
                  <img src={c.user_avatar || '/avatar.svg'} className="object-cover rounded-full w-7 h-7 ring-1 ring-white/40" />
                  <div className="px-3 py-2 border bg-white/60 dark:bg-zinc-700/50 border-white/40 dark:border-white/10 rounded-xl">
                    <div className="text-xs font-medium">{c.user_name || 'Пользователь'}</div>
                    <div className="text-sm">{c.body}</div>
                  </div>
                </div>
              ))}
              {comments.length === 0 && <div className="text-sm text-zinc-400">Комментариев пока нет</div>}
            </div>
          )}
          <div className="flex gap-2 mt-3">
            <input
              value={commentText}
              onChange={e=>setCommentText(e.target.value)}
              placeholder="Напишите комментарий…"
              className="flex-1 px-3 py-2 border rounded-full outline-none bg-white/70 dark:bg-zinc-700/50 border-white/40"
            />
            <button onClick={sendComment}
              className="px-4 py-2 text-white rounded-full bg-gradient-to-r from-pink-400 to-rose-400">
              Отправить
            </button>
          </div>
        </div>
      )}
    </div>
  );
}