import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import client from "../api/client";
import StatusBadge from "../components/StatusBadge.jsx";
import { useAuth } from "../context/AuthContext.jsx";

// WF-02 — circular list view (FR-27–29). Live data, search + filters,
// per-user acknowledgement status. Employees see only their assigned circulars;
// Managers/Administrators see all.
const CATEGORIES = [
  "Anti-Money Laundering",
  "Technology Risk",
  "Capital Adequacy",
  "Consumer Protection",
  "General",
];
const STATUSES = ["Unread", "Read", "Acknowledged"];

const PRIORITY_STYLE = {
  High: "bg-red-50 text-status-unread",
  Medium: "bg-amber-50 text-status-read",
  Low: "bg-slate-100 text-ink-muted",
};

export default function EmployeeDashboard() {
  const { user } = useAuth();
  const isStaff = user?.role !== "Employee";
  const [items, setItems] = useState([]);
  const [q, setQ] = useState("");
  const [category, setCategory] = useState("");
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const params = {};
    if (q.trim()) params.q = q.trim();
    if (category) params.category = category;
    if (status) params.status = status;
    try {
      const res = await client.get("/circulars", { params });
      setItems(res.data);
    } finally {
      setLoading(false);
    }
  }

  // Refetch when filters change; search runs on submit.
  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [category, status]);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <div className="text-xs font-semibold uppercase tracking-wide text-brand-600">
            WF-02
          </div>
          <h1 className="text-xl font-bold text-ink">
            {isStaff ? "All Circulars" : "My Circulars"}
          </h1>
        </div>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            load();
          }}
          className="flex flex-wrap items-center gap-2"
        >
          <input
            className="input max-w-xs"
            placeholder="Search title, number, summary…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          <select className="input" value={category} onChange={(e) => setCategory(e.target.value)}>
            <option value="">All categories</option>
            {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
          </select>
          <select className="input" value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="">All statuses</option>
            {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
          <button type="submit" className="btn-primary">Search</button>
        </form>
      </div>

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-ink-surface text-left text-xs uppercase text-ink-muted">
            <tr>
              <th className="px-4 py-3 font-medium">Circular</th>
              <th className="px-4 py-3 font-medium">Title</th>
              <th className="px-4 py-3 font-medium">Category</th>
              <th className="px-4 py-3 font-medium">Priority</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-ink-line">
            {loading ? (
              <tr><td colSpan="6" className="px-4 py-8 text-center text-ink-muted">Loading…</td></tr>
            ) : items.length === 0 ? (
              <tr><td colSpan="6" className="px-4 py-8 text-center text-ink-muted">No circulars found.</td></tr>
            ) : (
              items.map((c) => (
                <tr key={c.id} className="hover:bg-ink-surface/60">
                  <td className="px-4 py-3 font-mono text-xs text-ink-muted">{c.circular_number}</td>
                  <td className="px-4 py-3 font-medium text-ink">{c.title}</td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-1">
                      {c.categories?.map((cat) => (
                        <span key={cat} className="badge bg-brand-50 text-brand-700">{cat}</span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`badge ${PRIORITY_STYLE[c.priority] || "bg-slate-100 text-ink-muted"}`}>
                      {c.priority}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    {c.my_status ? <StatusBadge status={c.my_status} /> : <span className="text-xs text-ink-muted">—</span>}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Link to={`/circulars/${c.id}`} className="btn-ghost py-1.5 text-xs">Open</Link>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
