import { useEffect, useRef, useState } from "react";
import client from "../api/client";
import Icon from "./Icon.jsx";

// FR-22: in-app notification indicator with unread count + dropdown list.
export default function NotificationBell() {
  const [open, setOpen] = useState(false);
  const [data, setData] = useState({ unread: 0, items: [] });
  const ref = useRef(null);

  async function load() {
    try {
      const res = await client.get("/notifications");
      setData(res.data);
    } catch {
      /* ignore — bell stays empty if the call fails */
    }
  }

  useEffect(() => {
    load();
    const id = setInterval(load, 60000); // refresh every minute
    return () => clearInterval(id);
  }, []);

  // close on outside click
  useEffect(() => {
    function onClick(e) {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    }
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, []);

  async function markAll() {
    await client.post("/notifications/read-all");
    load();
  }

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={() => setOpen((o) => !o)}
        className="relative grid h-9 w-9 place-items-center rounded-lg border border-ink-line bg-white hover:bg-ink-surface"
        title="Notifications"
      >
        <Icon name="bell" className="h-5 w-5 text-ink" />
        {data.unread > 0 && (
          <span className="absolute -right-1 -top-1 grid h-4 min-w-4 place-items-center rounded-full bg-status-unread px-1 text-[10px] font-bold text-white">
            {data.unread > 9 ? "9+" : data.unread}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 z-20 mt-2 w-80 overflow-hidden rounded-xl border border-ink-line bg-white shadow-card">
          <div className="flex items-center justify-between border-b border-ink-line px-4 py-2">
            <span className="text-sm font-semibold text-ink">Notifications</span>
            {data.unread > 0 && (
              <button onClick={markAll} className="text-xs text-brand-600 hover:underline">
                Mark all read
              </button>
            )}
          </div>
          <div className="max-h-80 overflow-auto">
            {data.items.length === 0 ? (
              <p className="px-4 py-6 text-center text-sm text-ink-muted">No notifications.</p>
            ) : (
              data.items.map((n) => (
                <div
                  key={n.id}
                  className={`border-b border-ink-line px-4 py-3 text-sm ${
                    n.is_read ? "text-ink-muted" : "bg-brand-50/40 text-ink"
                  }`}
                >
                  <div>{n.message}</div>
                  <div className="mt-1 text-[11px] text-ink-muted">
                    {n.created_at ? new Date(n.created_at).toLocaleString() : ""}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}
