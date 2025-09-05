import React, { useEffect, useState } from "react";
import { API } from "../api";
import Icon from "../components/Icon";
import { CONFIG } from "../config";

export default function FeedScreen() {
  const [items, setItems] = useState<any[]>([]);
  const [offset, setOffset] = useState(0);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    load();
    // eslint-disable-next-line
  }, []);

  const load = async () => {
    if (busy) return;
    setBusy(true);
    try {
      const data = await API.feed(10, offset);
      setItems((s) => [...s, ...data]);
      setOffset((o) => o + 10);
    } catch (e) {
      console.error(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="page">
      <h2>Лента</h2>
      {items.map((it) => (
        <div className="card" key={it.id}>
          <div className="row">
            <strong>{it.user_name || "Рыбак"}</strong>
            <span className="muted">{new Date(it.created_at).toLocaleString()}</span>
          </div>
          <div className="row">
            <span>{it.species}</span>
          </div>
          {it.media_url && <img src={it.media_url} alt="" className="w100" />}
          <div className="row actions">
            <span><Icon name={CONFIG.icons.like} /> {it.likes_count ?? 0}</span>
            <span><Icon name={CONFIG.icons.comment} /> {it.comments_count ?? 0}</span>
            <span><Icon name={CONFIG.icons.share} /></span>
          </div>
        </div>
      ))}
      <div className="center">
        <button onClick={load} disabled={busy} className="btn">
          {busy ? "Загрузка..." : "Ещё"}
        </button>
      </div>
    </div>
  );
}
