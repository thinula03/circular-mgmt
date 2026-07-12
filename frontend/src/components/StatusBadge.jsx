// Acknowledgement status colour coding, consistent across WF-02/03/04 (thesis §4.8):
//   Unread = red | Read = amber | Acknowledged = green
const STYLES = {
  Unread: "bg-red-50 text-status-unread",
  Read: "bg-amber-50 text-status-read",
  Acknowledged: "bg-green-50 text-status-ack",
};

// Friendlier employee-facing labels. The stored status value is unchanged
// ("Acknowledged"); only the wording shown to the employee differs.
const LABELS = {
  Unread: "New",
  Read: "Read",
  Acknowledged: "Confirmed",
};

export default function StatusBadge({ status }) {
  const dot = {
    Unread: "bg-status-unread",
    Read: "bg-status-read",
    Acknowledged: "bg-status-ack",
  }[status];
  return (
    <span className={`badge ${STYLES[status] || "bg-slate-100 text-ink-muted"}`}>
      <span className={`h-1.5 w-1.5 rounded-full ${dot || "bg-slate-400"}`} />
      {LABELS[status] || status}
    </span>
  );
}
