# Phase 6 — RAG Chatbot (Step-by-Step Log)

**Project:** Smart Circular Summarization & Management System for Banking
**Author:** H.M.C. Hasanthi (CT/2020/055) · CTEC 43018
**Goal of Phase 6:** add the Retrieval-Augmented Generation (RAG) chatbot so employees
can ask natural-language questions about stored circulars and get grounded, cited
answers — Sentence-BERT retrieval over a FAISS index, with BART generating the answer.

**Requirements covered**
| FR | Requirement | Priority |
|----|-------------|----------|
| FR-36 | Chat panel embedded in the summary view | Must |
| FR-37 | Encode with Sentence-BERT, retrieve top-5 chunks from FAISS | Must |
| FR-38 | BART generates an answer (80–150 words) with citation | Must |
| FR-39 | Show chat history; store Q/A pairs in CHAT_LOG | Should |
| FR-40 | Rebuild the FAISS index after each new circular is published | Must |

> Prerequisite: Phases 0–5 complete; published circulars with extracted text exist.
> AI models already downloaded (Phase 0). MySQL (XAMPP) running.

---

## Step 1 — Real FAISS vector index (FR-37, FR-40)

Rewrote `backend/app/ai/vector_index.py` (`USE_REAL_FAISS = True`):

- Loads **Sentence-BERT** (`all-MiniLM-L6-v2`) offline from the Phase-0 cache.
- `build(circulars)` — chunks each published circular's text (**200 words, 50-word
  overlap**), embeds the chunks, normalises them, and adds them to a FAISS
  `IndexFlatIP` index (cosine similarity). Chunk metadata (circular number + section)
  is stored alongside.
- The index + metadata are **persisted** to `backend/app/ai/index_store/` so they
  survive restarts (`_persist` / `_load`).
- `search(query, top_k=5)` — encodes the question and returns the top-K chunks (FR-37).

---

## Step 2 — Real chatbot service + BART answers (FR-38)

- `backend/app/ai/chatbot.py` (`ChatbotService`) — retrieves the top-5 chunks, builds a
  context, de-duplicates the citations, and calls the engine to generate an answer.
- Added `AIEngine.answer_with_context(question, context)` in
  `backend/app/ai/pipeline.py` — frames the question + retrieved context for BART so it
  produces a focused, grounded answer (~120 words, within the 80–150 range, FR-38).

---

## Step 3 — Wire index rebuild + persistence (FR-39, FR-40)

- `backend/app/blueprints/circulars.py` — after a circular is published, it rebuilds the
  FAISS index from all published circulars (FR-40).
- `backend/app/blueprints/chatbot.py` — the `/ask` endpoint lazily builds the index if it
  is empty (e.g. first use after a restart), then stores the Q/A pair + citations in
  `CHAT_LOG` (FR-39). `/history` returns the user's past conversation.

**Test the whole RAG pipeline standalone** (build index, ask a question):

```powershell
cd backend
& ".venv\Scripts\python.exe" -c "from app import create_app; from app.models.circular import Circular; from app.ai import get_index, get_chatbot; app=create_app();
import contextlib
with app.app_context():
    idx=get_index(app.config); print('index:', idx.build(Circular.query.filter_by(status='published').all()));
    r=get_chatbot(app.config).answer('What must banks do for high-value transactions?', top_k=5);
    print('ANSWER:', r['answer']); print('CITATIONS:', r['citations'])"
cd ..
```

Result: a grounded answer drawn from the AML circular, with citations to 07/2024,
03/2024 and 05/2024. (First run loads SBERT + BART, ~2–3 minutes on CPU.)

---

## Step 4 — Frontend chat panel (FR-36, FR-39)

- `frontend/src/components/ChatPanel.jsx` — a chat panel that loads prior history
  (FR-39), shows **user questions in blue bubbles** and **AI answers in amber bubbles**
  with the **source citations** (📄 circular number · section) beneath each answer, plus
  a live "Retrieving & generating…" indicator. The request timeout is 4 minutes to cover
  the first model load.
- `frontend/src/pages/CircularSummary.jsx` — replaced the WF-03 placeholder with the real
  `<ChatPanel />`.

**Verify the frontend builds:**

```powershell
cd frontend
npm run build        # -> built successfully
cd ..
```

---

## Step 5 — Browser verification

```powershell
# Backend (terminal 1)
cd backend ; & ".venv\Scripts\python.exe" run.py
# Frontend (terminal 2)
cd frontend ; npm run dev          # http://localhost:5173
```

Logged in as **employee**, opened a circular (WF-03), and asked
*"What is the deadline for compliance and who must banks appoint?"*:
- The question appeared in a blue bubble, then (after the first-load delay) the AI
  answered in an amber bubble: *"…Each bank shall appoint a dedicated Compliance
  Officer responsible for monitoring adherence to know-your-customer requirements."*
- Citations shown: **07/2024 · para 1/2, 03/2024 · para 1, 05/2024 · para 1**.
- No console errors.

**Confirm the Q/A pair persisted in CHAT_LOG (FR-39):**

```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "USE circular_management; SELECT id, user_id, LEFT(question,40) AS q, JSON_LENGTH(citations) AS cites FROM chat_log ORDER BY id DESC LIMIT 3;"
```

Result: one row — user 3, the question, 4 citations.

---

## Phase 6 outcome

| Step | Deliverable | Status |
|------|-------------|--------|
| 1 | FAISS vector index + SBERT embeddings (FR-37) | ✅ |
| 2 | ChatbotService + BART grounded answers (FR-38) | ✅ |
| 3 | Index rebuild on publish + CHAT_LOG storage (FR-39/40) | ✅ |
| 4 | WF-03 chat panel (blue/amber bubbles + citations) | ✅ |
| 5 | Browser verification + CHAT_LOG persistence | ✅ |

**Result:** employees can ask natural-language questions about the stored circulars and
receive grounded answers with source citations, generated entirely on the local server.
The FAISS index rebuilds automatically when new circulars are published.

> Performance note: the **first** chat request takes ~3–4 minutes on CPU (it loads
> Sentence-BERT and BART); the panel waits up to 4 minutes, and later questions are much
> faster because the models stay resident. The chunking strategy (200 words / 50-word
> overlap) follows the AWS guidance cited in the thesis.
