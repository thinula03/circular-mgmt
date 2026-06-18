import { useEffect, useState } from "react";
import client from "../api/client";
import { useAuth } from "../context/AuthContext.jsx";

// Change requests: managers track the requests they raised; administrators
// reply and mark each one Solved or Not Solved.
const STATUS_STYLE = {
  Open: "bg-amber-50 text-status-read",
  Solved: "bg-green-50 text-status-ack",
  "Not Solved": "bg-red-50 text-status-unread",
};

export default function Requests() {
  const { user } = useAuth();
  const isAdmin = user?.role === "Administrator";
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [resolving, setResolving] = useState(null); // request being resolved
  const [reply, setReply] = useState("");
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState("");

  async function load() {
    setLoading(true);
    try {
      const res = await client.get("/circulars/requests");
      setItems(res.data);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function resolve(status) {
    setBusy(true);
    try {
      await client.post(`/circulars/requests/${resolving.id}/resolve`, { status, reply });
      setResolving(null);
      setReply("");
      setMsg(`Request marked ${status}.`);
      setTimeout(() => setMsg(""), 4000);
      await load();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <div className="text-xs font-semibold uppercase tracking-wide text-brand-600">
          {isAdmin ? "Administration" : "My activity"}
        </div>
        <h1 className="text-xl font-bold text-ink">
          {isAdmin ? "Requests" : "My Requests"}
        </h1>
      </div>

      {msg && <div className="rounded-lg bg-brand-50 px-3 py-2 text-sm text-brand-700">{msg}</div>}

      {loading ? (
        <p className="text-ink-muted">Loading…</p>
      ) : items.length === 0 ? (
        <div className="card p-8 text-center text-sm text-ink-muted">
          {isAdmin ? "No change requests yet." : "You haven't raised any requests yet."}
        </div>
      ) : (
        <div className="space-y-3">
          {items.map((r) => (
            <div key={r.id} className="card p-5">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-xs text-ink-muted">{r.circular_number}</span>
                  <span className="font-medium text-ink">{r.circular_title}</span>
                </div>
                <span className={`badge ${STATUS_STYLE[r.status] || "bg-slate-100 text-ink"}`}>
                  {r.status}
                </span>
              </div>

              <p className="mt-2 text-sm text-ink">{r.message}</p>
              <div className="mt-1 text-[11px] text-ink-muted">
                {isAdmin ? `By ${r.requester} · ` : ""}
                {r.created_at ? new Date(r.created_at).toLocaleString() : ""}
              </div>

              {/* Admin reply, once resolved */}
              {r.admin_reply && (
                <div className="mt-3 rounded-lg bg-ink-surface p-3 text-sm">
                  <div className="text-xs font-semibold uppercase text-ink-muted">
                    Administrator reply{r.resolved_by ? ` · ${r.resolved_by}` : ""}
                  </div>
                  <div className="mt-1 text-ink">{r.admin_reply}</div>
                </div>
              )}

              {/* Admin actions for open requests */}
              {isAdmin && r.status === "Open" && (
                <div className="mt-3">
                  {resolving?.id === r.id ? (
                    <div className="space-y-2">
                      <textarea
                        className="input h-20"
                        placeholder="Reply to the manager (optional)…"
                        value={reply}
                        onChange={(e) => setReply(e.target.value)}
                      />
                      <div className="flex gap-2">
                        <button onClick={() => resolve("Solved")} disabled={busy}
                          className="btn-primary">Mark Solved</button>
                        <button onClick={() => resolve("Not Solved")} disabled={busy}
                          className="btn-ghost text-status-unread">Not Solved</button>
                        <button onClick={() => { setResolving(null); setReply(""); }}
                          className="btn-ghost">Cancel</button>
                      </div>
                    </div>
                  ) : (
                    <button onClick={() => { setResolving(r); setReply(""); }}
                      className="btn-ghost text-xs">Reply / Resolve</button>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
