// Renders a structured AI summary: section headers ("Overview:", "Key Points:"),
// bullet lines ("- ..."), and plain paragraphs. Keeps the summary readable
// instead of one dense blob.
export default function SummaryText({ text }) {
  if (!text) return null;

  const lines = text.split("\n");
  const blocks = [];
  let bullets = [];
  const flush = () => {
    if (bullets.length) {
      blocks.push({ type: "ul", items: bullets });
      bullets = [];
    }
  };

  lines.forEach((raw) => {
    const line = raw.trim();
    if (!line) return flush();
    if (line.startsWith("- ") || line.startsWith("• ")) {
      bullets.push(line.slice(2));
      return;
    }
    flush();
    if (/^[A-Za-z][\w /&-]{0,30}:$/.test(line)) {
      blocks.push({ type: "h", text: line.replace(/:$/, "") });
    } else {
      blocks.push({ type: "p", text: line });
    }
  });
  flush();

  return (
    <div className="space-y-2">
      {blocks.map((b, i) =>
        b.type === "h" ? (
          <div key={i} className="text-xs font-semibold uppercase tracking-wide text-brand-600">
            {b.text}
          </div>
        ) : b.type === "ul" ? (
          <ul key={i} className="space-y-1 pl-1 text-ink">
            {b.items.map((it, j) => {
              // If the item already carries its own label like "(a)", "1.", "b)",
              // use that as the marker; otherwise add a bullet. Avoids "• (a) …".
              const hasMarker = /^\(?[a-z0-9]{1,3}[).]/i.test(it.trim());
              return (
                <li key={j} className="flex gap-2 leading-relaxed">
                  {!hasMarker && <span className="select-none text-brand-500">•</span>}
                  <span>{it}</span>
                </li>
              );
            })}
          </ul>
        ) : (
          <p key={i} className="leading-relaxed text-ink">{b.text}</p>
        )
      )}
    </div>
  );
}
