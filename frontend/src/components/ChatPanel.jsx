import { useEffect, useRef, useState } from "react";
import client from "../api/client";
import Icon from "./Icon.jsx";

// WF-03 RAG chatbot panel (FR-36–39), ChatGPT-style.
//   * No `circularId`  -> GLOBAL chat: ask about any published circular.
//   * With `circularId` -> SCOPED chat: ask about that one circular only.
// Messages are grouped into conversations; a history list lets the user reopen
// past conversations or start a new chat. Global and per-circular conversations
// are kept in separate history lists (scoped by the same `circularId`).
export default function ChatPanel({ circularId = null }) {
  const scoped = circularId != null;

  const [conversations, setConversations] = useState([]);
  const [activeId, setActiveId] = useState(null);
  const [messages, setMessages] = useState([]); // {role:'user'|'ai', text, citations?}
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);      // awaiting an answer
  const [historyOpen, setHistoryOpen] = useState(false);
  const scrollRef = useRef(null);

  const params = scoped ? { circular_id: circularId } : {};

  async function loadConversations() {
    try {
      const { data } = await client.get("/chatbot/conversations", { params });
      setConversations(data);
      return data;
    } catch {
      return [];
    }
  }

  // Refresh the history list whenever the scope changes; start on a fresh chat.
  useEffect(() => {
    setActiveId(null);
    setMessages([]);
    setHistoryOpen(false);
    loadConversations();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [circularId]);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight });
  }, [messages, loading]);

  function newChat() {
    setActiveId(null);
    setMessages([]);
    setInput("");
    setHistoryOpen(false);
  }

  async function openConversation(id) {
    try {
      const { data } = await client.get(`/chatbot/conversations/${id}`);
      const hist = [];
      (data.messages || []).forEach((m) => {
        hist.push({ role: "user", text: m.question });
        hist.push({ role: "ai", text: m.answer, citations: m.citations });
      });
      setMessages(hist);
      setActiveId(id);
      setHistoryOpen(false);
    } catch {
      /* ignore */
    }
  }

  async function deleteConversation(id, e) {
    e.stopPropagation();
    try {
      await client.delete(`/chatbot/conversations/${id}`);
      if (id === activeId) newChat();
      loadConversations();
    } catch {
      /* ignore */
    }
  }

  async function send(e) {
    e.preventDefault();
    const question = input.trim();
    if (!question || loading) return;
    setMessages((m) => [...m, { role: "user", text: question }]);
    setInput("");
    setLoading(true);
    try {
      const body = { question, conversation_id: activeId };
      if (scoped) body.circular_id = circularId;
      const { data } = await client.post("/chatbot/ask", body, { timeout: 240000 });
      setMessages((m) => [...m, { role: "ai", text: data.answer, citations: data.citations }]);
      setActiveId(data.conversation_id);
      loadConversations(); // reflect the new/updated conversation in history
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
      {/* Header */}
      <div className="flex items-center justify-between border-b border-ink-line px-4 py-3">
        <span className="text-sm font-semibold text-ink">
          {scoped ? "Ask about this circular" : "Circular Assistant"}
        </span>
        <div className="flex items-center gap-1">
          <button
            onClick={() => setHistoryOpen((o) => !o)}
            className={`grid h-8 w-8 place-items-center rounded-lg border border-ink-line hover:bg-ink-surface ${
              historyOpen ? "bg-ink-surface text-brand-600" : "text-ink"
            }`}
            title="Chat history"
          >
            <Icon name="history" className="h-4 w-4" />
          </button>
          <button
            onClick={newChat}
            className="grid h-8 w-8 place-items-center rounded-lg border border-ink-line text-ink hover:bg-ink-surface"
            title="New chat"
          >
            <Icon name="plus" className="h-4 w-4" />
          </button>
        </div>
      </div>

      {historyOpen ? (
        /* History list */
        <div className="flex-1 overflow-auto p-2">
          {conversations.length === 0 ? (
            <p className="mt-8 text-center text-sm text-ink-muted">No past chats yet.</p>
          ) : (
            conversations.map((c) => (
              <div
                key={c.id}
                onClick={() => openConversation(c.id)}
                className={`group flex cursor-pointer items-center justify-between rounded-lg px-3 py-2 text-sm hover:bg-ink-surface ${
                  c.id === activeId ? "bg-brand-50 text-brand-700" : "text-ink"
                }`}
              >
                <div className="min-w-0">
                  <div className="truncate">{c.title}</div>
                  <div className="text-[11px] text-ink-muted">
                    {c.message_count} message{c.message_count === 1 ? "" : "s"}
                    {c.updated_at ? ` · ${new Date(c.updated_at).toLocaleDateString()}` : ""}
                  </div>
                </div>
                <button
                  onClick={(e) => deleteConversation(c.id, e)}
                  className="ml-2 hidden text-ink-muted hover:text-status-unread group-hover:block"
                  title="Delete chat"
                >
                  <Icon name="trash" className="h-4 w-4" />
                </button>
              </div>
            ))
          )}
        </div>
      ) : (
        /* Messages */
        <div ref={scrollRef} className="flex-1 space-y-3 overflow-auto p-4">
          {messages.length === 0 && !loading && (
            <p className="mt-8 text-center text-sm text-ink-muted">
              {scoped ? (
                <>Ask a question about this circular.</>
              ) : (
                <>
                  Ask a question about any published circular — e.g.<br />
                  <span className="italic">"What is the deadline for enhanced due diligence?"</span>
                </>
              )}
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
      )}

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
