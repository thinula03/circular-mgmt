import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import client from "../api/client";

// Compliance Officer approval queue: circulars awaiting approval (four-eyes).
// Open a circular to read the summary, then approve or reject it there.
export default function Approvals() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    client.get("/circulars/pending")
      .then((r) => setItems(r.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-4">
      <div>
        <div className="text-xs font-semibold uppercase tracking-wide text-brand-600">Approvals</div>
        <h1 className="text-xl font-bold text-ink">Circulars awaiting approval</h1>
      </div>

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-ink-surface text-left text-xs uppercase text-ink-muted">
            <tr>
              <th className="px-4 py-3 font-medium">Circular</th>
              <th className="px-4 py-3 font-medium">Title</th>
              <th className="px-4 py-3 font-medium">Category</th>
              <th className="px-4 py-3 font-medium">Priority</th>
              <th className="px-4 py-3 text-right font-medium">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-ink-line">
            {loading ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-ink-muted">Loading…</td></tr>
            ) : items.length === 0 ? (
              <tr><td colSpan={5} className="px-4 py-8 text-center text-ink-muted">Nothing awaiting approval.</td></tr>
            ) : (
              items.map((c) => (
                <tr key={c.id} className="hover:bg-ink-surface/60">
                  <td className="px-4 py-3 font-mono text-xs text-ink-muted">{c.circular_number}</td>
                  <td className="px-4 py-3 font-medium text-ink">{c.title}</td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-1">
                      {(c.categories || []).map((cat) => (
                        <span key={cat} className="badge bg-brand-50 text-brand-700">{cat}</span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-3">{c.priority}</td>
                  <td className="px-4 py-3 text-right">
                    <Link to={`/circulars/${c.id}`} className="btn-primary py-1.5 text-xs">Review</Link>
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
