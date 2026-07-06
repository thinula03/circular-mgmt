import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import client from "../api/client";
import EntityTags from "../components/EntityTags.jsx";
import StatusBadge from "../components/StatusBadge.jsx";
import ChatPanel from "../components/ChatPanel.jsx";
import Icon from "../components/Icon.jsx";
import { useAuth } from "../context/AuthContext.jsx";

// WF-03 — Circular summary view with (Phase 6) embedded RAG chatbot.
// Left: AI summary, NER tags, classifications, original PDF, Acknowledge.
// Right: chat panel placeholder until Phase 6.
export default function CircularSummary() {
  const { id } = useParams();
  const { user } = useAuth();
  const isAdmin = user?.role === "Administrator";
  const isStaff = isAdmin || user?.role === "Manager";
  const [circular, setCircular] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [acking, setAcking] = useState(false);
  const [broadcasting, setBroadcasting] = useState(false);
  const [broadcastMsg, setBroadcastMsg] = useState("");
  const [regenerating, setRegenerating] = useState(false);
  const [previewUrl, setPreviewUrl] = useState("");
  const [previewLoading, setPreviewLoading] = useState(false);
  const [previewError, setPreviewError] = useState("");

  async function load() {
    setLoading(true);
    try {
      const res = await client.get(`/circulars/${id}`);
      setCircular(res.data);
    } catch (err) {
      setError(err.response?.data?.error || "Could not load circular.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  async function acknowledge() {
    setAcking(true);
    try {
      const res = await client.post(`/summaries/${id}/acknowledge`);
      setCircular((c) => ({ ...c, my_status: res.data.status, my_ack: res.data }));
    } finally {
      setAcking(false);
    }
  }

  async function broadcastAll() {
    setBroadcasting(true);
    setBroadcastMsg("");
    try {
      const res = await client.post(`/circulars/${id}/broadcast`);
      const d = res.data.distribution;
      setBroadcastMsg(`Sent to all departments — ${d.recipient_count} recipient${
        d.recipient_count === 1 ? "" : "s"} notified.`);
    } catch (err) {
      setBroadcastMsg(err.response?.data?.error || "Broadcast failed.");
    } finally {
      setBroadcasting(false);
    }
  }

  async function regenerate() {
    setRegenerating(true);
    setBroadcastMsg("");
    try {
      await client.post(`/circulars/${id}/summarize?regenerate=true`, {}, { timeout: 600000 });
      await load();
      setBroadcastMsg("Summary re-generated.");
    } catch (err) {
      setBroadcastMsg(err.response?.data?.error || "Re-generate failed.");
    } finally {
      setRegenerating(false);
    }
  }

  async function openPreview() {
    setPreviewLoading(true);
    setPreviewError("");
    try {
      const res = await client.get(`/circulars/${id}/preview`, { responseType: "blob" });
      const blob = new Blob([res.data], { type: "application/pdf" });
      setPreviewUrl(URL.createObjectURL(blob));
    } catch (err) {
      setPreviewError(err.response?.data?.error || "Could not load the PDF preview.");
    } finally {
      setPreviewLoading(false);
    }
  }

  function closePreview() {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl("");
    setPreviewError("");
  }

  // Revoke any outstanding object URL when leaving the page.
  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
  }, [previewUrl]);

  async function downloadPdf() {
    // Authenticated download: fetch as a blob, then save.
    const res = await client.get(`/circulars/${id}/download`, { responseType: "blob" });
    const url = URL.createObjectURL(res.data);
    const a = document.createElement("a");
    a.href = url;
    a.download = `Circular_${circular.circular_number.replace("/", "-")}.pdf`;
    a.click();
    URL.revokeObjectURL(url);
  }

  if (loading) return <p className="text-ink-muted">Loading…</p>;
  if (error) return <p className="text-status-unread">{error}</p>;

  const summary = circular.summary;
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="text-xs font-semibold uppercase tracking-wide text-brand-600">
            WF-03 · {circular.circular_number}
          </div>
          <h1 className="text-xl font-bold text-ink">{circular.title}</h1>
        </div>
        <Link to="/" className="btn-ghost py-1.5 text-xs">← Back to list</Link>
      </div>

      <div className="grid gap-4 lg:grid-cols-5">
        {/* Left: summary + entities + acknowledge */}
        <section className="card space-y-4 p-6 lg:col-span-3">
          <div className="flex flex-wrap items-center gap-2 text-xs text-ink-muted">
            {circular.issue_date && <span>Issued {circular.issue_date}</span>}
            <span>· {circular.file_size_kb} KB</span>
            {circular.classifications?.map((c) => (
              <span key={c.id} className="badge bg-brand-50 text-brand-700">{c.category}</span>
            ))}
          </div>

          <div>
            <h2 className="mb-1 text-sm font-semibold text-ink">AI Summary</h2>
            {summary ? (
              <p className="rounded-lg bg-ink-surface p-3 text-sm leading-relaxed text-ink">
                {summary.summary_text}
              </p>
            ) : (
              <p className="text-sm text-ink-muted">No summary generated yet.</p>
            )}
          </div>

          {summary?.entities?.length > 0 && (
            <div>
              <div className="mb-1 text-xs font-medium uppercase text-ink-muted">Key entities</div>
              <EntityTags entities={summary.entities} />
            </div>
          )}

          <div className="flex flex-wrap items-center gap-2 border-t border-ink-line pt-4">
            {circular.my_status && <StatusBadge status={circular.my_status} />}
            {circular.my_status !== "Acknowledged" && circular.my_ack && (
              <button onClick={acknowledge} disabled={acking} className="btn-primary">
                {acking ? (
                  "Saving…"
                ) : (
                  <span className="flex items-center gap-2">
                    <Icon name="check" className="h-4 w-4" /> Acknowledge
                  </span>
                )}
              </button>
            )}
            <button onClick={openPreview} disabled={previewLoading} className="btn-ghost">
              {previewLoading ? (
                "Loading…"
              ) : (
                <span className="flex items-center gap-2">
                  <Icon name="eye" className="h-4 w-4" /> Preview
                </span>
              )}
            </button>
            <button onClick={downloadPdf} className="btn-ghost">Download PDF</button>
            {isStaff && (
              <button onClick={broadcastAll} disabled={broadcasting} className="btn-ghost">
                {broadcasting ? "Sending…" : "Send to all departments"}
              </button>
            )}
            {isAdmin && (
              <button onClick={regenerate} disabled={regenerating} className="btn-ghost">
                {regenerating ? (
                  <span className="flex items-center gap-2">
                    <span className="h-3 w-3 animate-spin rounded-full border-2 border-brand-400 border-t-transparent" />
                    Re-generating…
                  </span>
                ) : (
                  <span className="flex items-center gap-2">
                    <Icon name="sparkles" className="h-4 w-4" /> Re-generate summary
                  </span>
                )}
              </button>
            )}
          </div>
          {previewError && (
            <div className="rounded-lg bg-status-unread/10 px-3 py-2 text-sm text-status-unread">
              {previewError}
            </div>
          )}
          {broadcastMsg && (
            <div className="rounded-lg bg-brand-50 px-3 py-2 text-sm text-brand-700">
              {broadcastMsg}
            </div>
          )}
        </section>

        {/* Right: RAG chatbot (FR-36–39) */}
        <div className="lg:col-span-2">
          <ChatPanel />
        </div>
      </div>

      {/* Inline PDF preview modal */}
      {previewUrl && (
        <div
          className="fixed inset-0 z-30 grid place-items-center bg-black/40 p-4"
          onClick={closePreview}
        >
          <div
            className="card flex h-[90vh] w-full max-w-4xl flex-col p-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-sm font-semibold text-ink">
                {circular.circular_number} — {circular.title}
              </h2>
              <button onClick={closePreview} className="btn-ghost py-1.5 text-xs">Close</button>
            </div>
            <iframe
              src={previewUrl}
              title="Circular PDF preview"
              className="min-h-0 flex-1 rounded-lg border border-ink-line"
            />
          </div>
        </div>
      )}
    </div>
  );
}
