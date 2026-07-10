import { useEffect, useState } from "react";
import client from "../api/client";

// Manual classification + routing before publishing a circular (FR-18/19/20).
// Admin picks categories (from the managed taxonomy, can add new) and exactly
// which departments receive it, then publishes & distributes.
export default function PublishControls({ circularId, defaultCategories = [], onSubmitted }) {
  const [categories, setCategories] = useState([]);   // managed taxonomy
  const [depts, setDepts] = useState([]);
  const [selCats, setSelCats] = useState(() => new Set(defaultCategories));
  const [selDepts, setSelDepts] = useState(() => new Set());
  const [broadcast, setBroadcast] = useState(false);
  const [ackDays, setAckDays] = useState(7);
  const [newCat, setNewCat] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  useEffect(() => {
    client.get("/circulars/categories").then((r) => setCategories(r.data)).catch(() => {});
    client.get("/users/departments").then((r) => setDepts(r.data)).catch(() => {});
  }, []);

  function toggle(set, setter, val) {
    const next = new Set(set);
    next.has(val) ? next.delete(val) : next.add(val);
    setter(next);
  }

  async function addCategory() {
    const name = newCat.trim();
    if (!name) return;
    setErr("");
    try {
      const { data } = await client.post("/circulars/categories", { name });
      setCategories((c) => [...c, data].sort((a, b) => a.name.localeCompare(b.name)));
      setSelCats((s) => new Set(s).add(data.name));
      setNewCat("");
    } catch (e) {
      setErr(e.response?.data?.error || "Could not add category.");
    }
  }

  async function submit() {
    setErr("");
    if (selCats.size === 0) return setErr("Select at least one category.");
    if (!broadcast && selDepts.size === 0) return setErr("Select departments, or choose broadcast.");
    setBusy(true);
    try {
      const body = { categories: [...selCats], ack_days: ackDays, broadcast };
      if (!broadcast) body.department_ids = [...selDepts];
      const { data } = await client.post(`/circulars/${circularId}/submit`, body, { timeout: 60000 });
      onSubmitted?.(data);
    } catch (e) {
      setErr(e.response?.data?.error || "Submit failed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4 rounded-lg border border-ink-line bg-ink-surface/50 p-4">
      {/* Categories */}
      <div>
        <div className="mb-1 text-xs font-semibold uppercase text-ink-muted">Category</div>
        <div className="flex flex-wrap gap-2">
          {categories.map((c) => (
            <label key={c.id} className={`cursor-pointer rounded-full border px-3 py-1 text-sm ${
              selCats.has(c.name) ? "border-brand-500 bg-brand-50 text-brand-700" : "border-ink-line text-ink"}`}>
              <input type="checkbox" className="hidden" checked={selCats.has(c.name)}
                onChange={() => toggle(selCats, setSelCats, c.name)} />
              {c.name}
            </label>
          ))}
        </div>
        <div className="mt-2 flex gap-2">
          <input className="input" placeholder="Add a new category…" value={newCat}
            onChange={(e) => setNewCat(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); addCategory(); } }} />
          <button type="button" onClick={addCategory} className="btn-ghost whitespace-nowrap">+ Add</button>
        </div>
      </div>

      {/* Departments */}
      <div>
        <div className="mb-1 flex items-center justify-between">
          <span className="text-xs font-semibold uppercase text-ink-muted">Send to departments</span>
          <label className="flex cursor-pointer items-center gap-2 text-sm text-ink">
            <input type="checkbox" checked={broadcast} onChange={(e) => setBroadcast(e.target.checked)}
              className="h-4 w-4 rounded border-ink-line text-brand-500 focus:ring-brand-400" />
            All departments
          </label>
        </div>
        {!broadcast && (
          <div className="flex flex-wrap gap-2">
            {depts.map((d) => (
              <label key={d.id} className={`cursor-pointer rounded-full border px-3 py-1 text-sm ${
                selDepts.has(d.id) ? "border-brand-500 bg-brand-50 text-brand-700" : "border-ink-line text-ink"}`}>
                <input type="checkbox" className="hidden" checked={selDepts.has(d.id)}
                  onChange={() => toggle(selDepts, setSelDepts, d.id)} />
                {d.name}
              </label>
            ))}
            {depts.length === 0 && <span className="text-sm text-ink-muted">No departments found.</span>}
          </div>
        )}
      </div>

      {/* Deadline + publish */}
      <div className="flex flex-wrap items-end gap-4">
        <div>
          <label className="mb-1 block text-xs font-semibold uppercase text-ink-muted">
            Acknowledge within (days)
          </label>
          <input type="number" min="1" max="90" value={ackDays}
            onChange={(e) => setAckDays(Number(e.target.value) || 7)} className="input w-28" />
        </div>
        <button onClick={submit} disabled={busy} className="btn-primary">
          {busy ? "Submitting…" : "Submit for approval"}
        </button>
      </div>

      {err && <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-status-unread">{err}</div>}
    </div>
  );
}
