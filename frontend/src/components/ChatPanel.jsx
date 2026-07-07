import { useEffect, useRef, useState } from "react";
import client from "../api/client";
import Icon from "./Icon.jsx";

// WF-03 RAG chatbot panel (FR-36, FR-38, FR-39).
// User questions appear in blue bubbles; AI answers in amber bubbles with the
// source circular number + section citation below each answer.
export default function ChatPanel() {
  const [messages, setMessages] = useState([]); // {role:'user'|'ai', text, citations?}
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const scrollRef = useRef(null);

  // Load prior conversation (FR-39).
  useEffect(() => {
    client.get("/chatbot/history").then(({ data }) => {
      const hist = [];
      data.forEach((log) => {
        hist.push({ role: "user", text: log.question });
        hist.push({ role: "ai", text: log.answer, citations: log.citations });
      });
      setMessages(hist);
    }).catch(() => {});
  }, []);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight });
  }, [messages, loading]);

  async function send(e) {
    e.preventDefault();
    const question = input.trim();
    if (!question || loading) return;
    setMessages((m) => [...m, { role: "user", text: question }]);
    setInput("");
    setLoading(true);
    try {
      const { data } = await client.post("/chatbot/ask", { question }, { timeout: 240000 });
      setMessages((m) => [...m, { role: "ai", text: data.answer, citations: data.citations }]);
    } catch (err) {
      setMessages((m) => [
        ...m,
        { role: "ai", text: err.response?.data?.error || "Sorry, something went wrong.", citations: [] },
      ]);
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="card flex h-[32rem] flex-col p-0">
      <div className="border-b border-ink-line px-4 py-3 text-sm font-semibold text-ink">
        Ask the Circular Assistant
      </div>

      <div ref={scrollRef} className="flex-1 space-y-3 overflow-auto p-4">
        {messages.length === 0 && !loading && (
          <p className="mt-8 text-center text-sm text-ink-muted">
            Ask a question about any published circular — e.g.<br />
            <span className="italic">"What is the deadline for enhanced due diligence?"</span>
          </p>
        )}

        {messages.map((m, i) =>
          m.role === "user" ? (
            <div key={i} className="ml-auto max-w-[85%] rounded-2xl rounded-br-sm bg-brand-500 px-3 py-2 text-sm text-white">
              {m.text}
            </div>
          ) : (
            <div key={i} className="max-w-[90%] rounded-2xl rounded-bl-sm bg-amber-50 px-3 py-2 text-sm text-ink">
              <div className="whitespace-pre-wrap leading-relaxed">{m.text}</div>
              {m.citations?.length > 0 && (
                <div className="mt-2 flex flex-wrap gap-1">
                  {[...new Set(m.citations.map((c) => c.circular_number))].map((num) => (
                    <span key={num} className="badge bg-white text-[11px] text-ink-muted">
                      <Icon name="document" className="h-3 w-3" />
                      {num}
                    </span>
                  ))}
                </div>
              )}
            </div>
          )
        )}

        {loading && (
          <div className="max-w-[60%] rounded-2xl rounded-bl-sm bg-amber-50 px-3 py-2 text-sm text-ink-muted">
            <span className="inline-flex items-center gap-2">
              <span className="h-2 w-2 animate-bounce rounded-full bg-status-read" />
              Retrieving &amp; generating…
            </span>
          </div>
        )}
      </div>

      <form onSubmit={send} className="flex gap-2 border-t border-ink-line p-3">
        <input
          className="input"
          placeholder="Ask a question…"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          disabled={loading}
        />
        <button type="submit" disabled={loading || !input.trim()} className="btn-primary">
          Send
        </button>
      </form>
    </section>
  );
}
