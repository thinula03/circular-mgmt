// Lightweight dependency-free horizontal bar chart for the dashboard (FR-33).
// data: [{ label, value }]
export default function BarChart({ data = [], color = "bg-brand-500" }) {
  const max = Math.max(1, ...data.map((d) => d.value));
  if (data.length === 0) {
    return <p className="text-xs text-ink-muted">No data yet.</p>;
  }
  return (
    <div className="space-y-2">
      {data.map((d) => (
        <div key={d.label} className="flex items-center gap-2 text-xs">
          <span className="w-40 shrink-0 truncate text-ink-muted" title={d.label}>
            {d.label}
          </span>
          <div className="h-4 flex-1 overflow-hidden rounded bg-ink-surface">
            <div
              className={`h-full ${color} transition-all`}
              style={{ width: `${(d.value / max) * 100}%` }}
            />
          </div>
          <span className="w-8 shrink-0 text-right font-medium text-ink">{d.value}</span>
        </div>
      ))}
    </div>
  );
}
