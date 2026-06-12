// Lightweight scaffold banner used by pages whose full features land in later
// phases. Keeps the themed layout visible without faking functionality.
export default function PagePlaceholder({ wf, title, phase, children }) {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <div className="text-xs font-semibold uppercase tracking-wide text-brand-600">
            {wf}
          </div>
          <h1 className="text-xl font-bold text-ink">{title}</h1>
        </div>
        <span className="badge bg-amber-50 text-status-read">Arrives in {phase}</span>
      </div>
      <div className="card p-6">{children}</div>
    </div>
  );
}
