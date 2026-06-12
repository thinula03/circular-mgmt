// FR-15: display spaCy named entities as highlighted, colour-coded tags.
const TAG_STYLES = {
  DATE: "bg-blue-50 text-blue-700",
  MONEY: "bg-green-50 text-status-ack",
  NUMBER: "bg-green-50 text-status-ack",
  PERCENT: "bg-violet-50 text-violet-700",
  REGULATION: "bg-amber-50 text-status-read",
  ORG: "bg-brand-50 text-brand-700",
  PLACE: "bg-slate-100 text-ink",
};

export default function EntityTags({ entities = [] }) {
  if (!entities.length) {
    return <p className="text-xs text-ink-muted">No entities detected.</p>;
  }
  return (
    <div className="flex flex-wrap gap-2">
      {entities.map((e, i) => (
        <span
          key={`${e.text}-${i}`}
          className={`badge ${TAG_STYLES[e.label] || "bg-slate-100 text-ink"}`}
          title={e.label}
        >
          {e.text}
          <span className="ml-1 opacity-60">{e.label}</span>
        </span>
      ))}
    </div>
  );
}
