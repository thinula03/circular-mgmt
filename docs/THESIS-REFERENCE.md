# Thesis Reference — Smart Circular Summarization & Management System
_As-built system documentation for writing Chapters 3–8. Paraphrase into academic prose; every fact below reflects the actual implementation._

---

## 0. IMPORTANT — how the build diverged from the proposal
Update your Design/Methodology chapters to describe the **as-built** system, not the proposal:

| Area | Proposal | As built |
|------|----------|----------|
| Summarization | BART-large-CNN (abstractive) | **Local instruction-tuned LLM (Llama 3.2 3B via Ollama)**; BART kept only as offline fallback |
| Classification | Automatic (NLP/keyword) | **Manual expert classification** from a managed, editable taxonomy (keyword heuristic dropped as unreliable) |
| RAG answers | Retrieval + extractive passage | **Retrieval + local-LLM grounded generation** with citations and query rewriting |
| Governance | Single admin publishes | **Four-eyes (maker-checker) approval** — Admin submits, Compliance Officer approves/rejects |
| Extra features added | — | Circular **amendments/supersede**, **audit-log viewer**, PDF **OCR fallback**, in-app **preview** |

All AI inference is **local/offline** (Ollama, spaCy, BERT, FAISS) — a deliberate design choice for **data privacy** (confidential CBSL circulars never leave the machine), which is a core contribution.

---

## 1. System overview
A role-based web application that ingests CBSL regulatory circulars (PDF), extracts and cleans their text, summarizes them with a local LLM, classifies and routes them to departments through a four-eyes approval workflow, tracks per-employee acknowledgement/compliance, and provides a Retrieval-Augmented-Generation (RAG) chatbot for natural-language Q&A over the circulars — all with an immutable audit trail.

**Roles:** Administrator, Manager, Compliance Officer, Employee (RBAC).

---

## 2. Architecture (Chapter 4)
Three-tier, client–server:

- **Presentation tier** — React + Vite SPA, Tailwind CSS, React Router (client routing), Axios (HTTP), JWT stored client-side. Role-aware navigation and route guards.
- **Application tier** — Python **Flask** REST API (app-factory pattern), organised into **blueprints** (auth, users, circulars, summaries, dashboard, chatbot, notifications, audit). Services layer (security/RBAC, audit, distribution, email, pdf_extract, tokens). AI layer (pipeline, vector_index, chatbot, llm_summarizer).
- **Data tier** — **MySQL 8 / MariaDB** via SQLAlchemy ORM; local model cache for AI models; FAISS index + chunk metadata persisted to disk.

**Request flow:** SPA → `/api/*` (Vite dev proxy → Flask :5000) → JWT verified → RBAC checked → service/AI layer → MySQL → JSON response.

**AI runtime:** Ollama runs as a local service (localhost:11434); Flask calls it over HTTP. Hugging Face models load from a local offline cache (`HF_HUB_OFFLINE=1`).

---

## 3. Data model (Chapter 4 — ERD)
14 tables. Key entities and notable columns:

- **users** — id, username, email, full_name, password_hash (bcrypt), role, department_id (FK), is_active (soft delete), last_login, created_at. Roles: Administrator/Manager/Compliance Officer/Employee.
- **departments** — id, name, code, description.
- **circular_departments** — junction (circular_id, department_id, routed_at) — many-to-many routing.
- **circulars** — id, circular_number, title, issue_date, file_path, file_size_kb, extracted_text, priority (High/Medium/Low), **status**, ack_deadline, uploaded_by (FK), **amends_circular_id** (self-FK, amendment), **approved_by** (FK), **approved_at**, **distribution_intent** (JSON: departments/broadcast/ack_days), created_at, published_at.
  - **status lifecycle:** `uploaded → processing → review → pending_approval → published` (plus `failed`).
- **summaries** — id, circular_id (FK), summary_text, entities (JSON — key topics), word_count, bert_model, **bart_model** (records which model produced it — provenance), processing_seconds, rouge_score, created_at.
- **classifications** — id, circular_id, category, confidence, **is_manual**, created_at.
- **categories** — id, name (unique), created_at — admin-managed taxonomy.
- **acknowledgements** — id, circular_id, user_id, **status** (Unread/Read/Acknowledged), read_at, acknowledged_at, is_late. Drives red/amber/green colour coding.
- **notifications** — id, user_id, circular_id, message, **link** (in-app destination), is_read, created_at.
- **chat_conversations** — id, user_id, **circular_id** (NULL = global scope), title, created_at, updated_at.
- **chat_log** — id, user_id, conversation_id (FK), question, answer, citations (JSON), created_at.
- **change_requests** — id, circular_id, requester_id, message, status, admin_reply, resolved_by, created_at, resolved_at.
- **audit_log** — id, user_id, action, entity_type, entity_id, detail, created_at — **write-once/immutable** (no update/delete path).
- **vector_index_metadata** — RAG index stats.

**Schema migrations (evolution):** 001 init · 002 change_requests · 003 notification link · 004 chat conversations · 005 amendments · 006 category taxonomy · 007 approval workflow.

---

## 4. Technology stack (Chapter 5)
| Layer | Technology |
|-------|-----------|
| Backend framework | Python Flask 3, SQLAlchemy, Flask-JWT-Extended, Flask-CORS |
| Auth/security | JWT (30-min expiry), bcrypt (work factor 12), RBAC decorators |
| Database | MySQL 8 / MariaDB (PyMySQL) |
| PDF extraction | PyMuPDF (fitz); Tesseract OCR (pytesseract + Pillow) fallback for scans |
| NLP | spaCy `en_core_web_sm` (preprocessing, NER); BERT `bert-base-uncased` (embeddings, keyword ranking) |
| Summarization | Local LLM **Llama 3.2 3B** via **Ollama** (offline); BART-large-CNN fallback |
| RAG retrieval | Sentence-BERT `all-MiniLM-L6-v2` + **FAISS** (dense) + custom **BM25** (sparse), fused by **Reciprocal Rank Fusion**; optional QA reader `distilbert-squad` |
| RAG generation | Local LLM (Ollama) grounded answers + LLM query rewriting |
| Frontend | React 18, Vite, Tailwind CSS, React Router, Axios |
| Evaluation | rouge-score (ROUGE-1/2/L), bert-score (BERTScore) |

---

## 5. Implementation — modules & workflows (Chapter 5)

### 5.1 Ingestion & text extraction
1. Upload validated (PDF only, ≤20 MB, duplicate circular_number check).
2. **PyMuPDF** extracts per-page text. **OCR fallback**: pages detected as scanned (a single image covers the page) or with garbled/low text are re-OCR'd with **Tesseract** at 300 DPI; falls back to the embedded layer if OCR isn't installed.
3. **Noise cleaning:** repeated page **headers/footers** (lines recurring across ≥40% of pages) and stray **table artefacts** (lone `|`, bare page/section numbers, mangled markers like `(bo)`) are removed so they don't pollute summaries or the RAG index.

### 5.2 Summarization (core contribution)
- **Length policy:** ~1/3 of the source, floored at 80 and capped at ~450 words (concise, page-scale).
- **Structure:** the LLM is prompted to output **Overview** (2–3 sentences) + **Key Points** (6–10 consolidated bullets), focusing on obligations/procedures/deadlines, not glossary definitions.
- **Faithfulness prompt:** "use only the circular, preserve exact figures/dates, do not invent." A system prompt prevents refusals; output is validated and retried; preamble/echo/markdown are stripped.
- **Provenance:** each summary records which model produced it (`llama3.2:3b` vs `facebook/bart-large-cnn`).
- **Fallback:** if Ollama is unavailable, an extractive BERT-selection + BART pipeline produces a structured summary.
- **Key topics:** the LLM extracts 5 key terms; fallback is a KeyBERT-style method (spaCy noun-phrases → BERT embeddings → MMR ranking) with circular-number recognition.

### 5.3 Classification & routing (manual, expert-driven)
- Categories come from an **editable taxonomy** (`categories` table; seeded with AML, Technology Risk, Capital Adequacy, Consumer Protection, General).
- The Administrator **manually assigns** categories and **selects the target departments** at submit time (stored as `distribution_intent`). This replaced the unreliable keyword auto-classifier.

### 5.4 Four-eyes approval workflow (governance contribution)
Maker–checker separation of duties:
1. **Maker (Admin):** upload → generate summary (→ `review`) → pick category + departments → **Submit for approval** (→ `pending_approval`). Compliance Officers are notified.
2. **Checker (Compliance Officer):** reviews the summary in an **approval queue** → **Approve** (→ publish + distribute) or **Reject with a reason** (→ back to `review`; submitter notified).
3. Every submit/approve/reject is recorded in the audit log; an **Approval History** view shows the trail.

### 5.5 Distribution, acknowledgement & reminders
- On approval, the circular is routed to the chosen departments (recorded in `circular_departments`); every active Employee/Manager there gets an **acknowledgement record (Unread)**, an **in-app notification** (deep link), and an **email**.
- Opening marks **Read**; confirming marks **Acknowledged** (green). A **reminder** job nudges un-acknowledged staff near/after the deadline and flags overdue as late.

### 5.6 Amendments / supersede
- A circular can **amend** an earlier one (self-reference). "Superseded" is **derived** (a published circular points at it). Badges/banners cross-link both; in RAG, superseded circulars are demoted and their citations labelled "(superseded)".

### 5.7 RAG chatbot
- **Scopes:** global (any circular) and per-circular; ChatGPT-style **conversations** with history.
- **Query rewriting:** the LLM cleans the user's question (fixes typos, rejoins split words, keeps domain terms) before retrieval.
- **Hybrid retrieval:** dense (SBERT/FAISS) + sparse (BM25) fused via **Reciprocal Rank Fusion**, scoped by circular.
- **Grounded generation:** retrieved chunks → local LLM → concise, cited answer; says "could not find it" when unsupported; forms/annexures are named with a download prompt (not reproduced). Extractive QA reader is a fallback.

### 5.8 Security & NFRs
- **Authentication:** JWT (30-min expiry) + 30-min idle auto-logout.
- **Authorization:** RBAC via `roles_required` decorators on every protected endpoint.
- **Passwords:** bcrypt, work factor 12; reset via time-limited signed token.
- **Audit trail:** immutable, write-once `audit_log`; admin viewer with filters; **failed logins** and logout logged.
- **Privacy (NFR-08):** all AI inference runs locally/offline.
- **Integrity:** duplicate detection, input validation, file-type/size checks.

### 5.9 Analytics dashboard
KPIs (published/acknowledged/pending/overdue), overall ack rate, category & status charts, per-department and per-circular compliance with employee drill-down, AI performance (summaries, avg processing time, avg ROUGE, models used), CSV/PDF export.

---

## 6. Key algorithms (Chapter 5 — worth a subsection each)
1. **Reciprocal Rank Fusion (RRF):** fused_score(d) = Σ 1/(k + rank_i(d)), k=60, over dense and sparse rankings — combines semantic and keyword relevance; robust to exact terms/numbers/acronyms that dense embeddings miss.
2. **OCR-need detection:** page is scanned (single image covers ≥50% area) OR text layer sparse/garbled → re-OCR.
3. **Header/footer removal:** lines whose normalized form recurs on ≥40% of pages are boilerplate → dropped.
4. **Structured, faithful summarization prompt** (Overview + Key Points, obligations-focused, grounded).
5. **LLM query rewriting** for retrieval robustness to typos.
6. **Supersede demotion** in retrieval ranking.

---

## 7. API surface (appendix)
Grouped by blueprint (`/api/...`): `auth` (login, logout, me, forgot/reset/change-password), `users` (+departments), `circulars` (upload, get, download, preview, summarize, **submit/approve/reject**, pending, approval-history, categories CRUD, classification, broadcast, amendments, reminders), `summaries` (acknowledge), `chatbot` (ask, conversations CRUD), `notifications`, `dashboard` (overview, trends, circulars, ai-performance, export), `audit` (list, actions).

---

## 8. Testing & Evaluation (Chapter 6)

### 8.1 Summarization quality
- **Metrics:** ROUGE-1/2/L (lexical overlap) + **BERTScore** (semantic) against hand-written reference summaries (15–25 circulars).
- **Comparison:** local LLM vs BART baseline (toggle `USE_LLM_SUMMARY`, regenerate, re-score) → report improvement.
- **Faithfulness:** manual check of a sample → % of summaries with zero unsupported claims (critical for compliance).
- Harness: `backend/eval_summary.py`, references in `backend/eval_references.json`.

### 8.2 RAG chatbot
- **Retrieval hit-rate** (did the correct circular appear in citations) and **answer accuracy** (expected keywords present) on a question set. Compare hybrid vs dense-only. Harness: `backend/eval_rag.py`.

### 8.3 Functional testing
- Requirements-traceability matrix: each FR → test case → pass/fail. (Recommend a pytest suite for auth, RBAC, extraction, workflow, retrieval.)

### 8.4 Usability (UAT)
- Structured test cases + a **SUS** questionnaire and Likert ratings (coherence, coverage, usefulness) with bank staff. Report SUS score and satisfaction.

### 8.5 Performance / NFR
- Summarization latency (and processing-time reduction vs manual reading), chatbot response time, on the local hardware (note the CPU/GPU trade-off on the test machine).

---

## 9. Results & Discussion (Chapter 7 — how to present)
- Tables: ROUGE/BERTScore per circular + averages; LLM-vs-BART comparison; RAG hit-rate/accuracy; UAT scores.
- Discussion: tie results back to the **research gap** (no such tool validated for Sri Lankan government banks); interpret where the LLM helps most; limitations (hardware-bound latency, small-model trade-offs, OCR quality on poor scans); threats to validity (small dataset, single institution).

---

## 10. Conclusion & Future Work (Chapter 8)
- **Achieved:** an offline, privacy-preserving, AI-assisted circular management platform with human-validated summaries, hybrid RAG Q&A, four-eyes governance, and full auditability — demonstrated on real CBSL circulars.
- **Future work:** background/async summarization; fine-tuning/quantized models for speed; **multi-language (Sinhala/Tamil)**; LLM-assisted category suggestion; amendment diffing; multi-institution deployment; real SMTP + escalation/digests; Dockerised deployment.

---

## 11. Figures / screenshots checklist (capture now)
Login · role-based sidebar · circular list · upload → generate summary (with model label) · category+department picker · submit-for-approval · Compliance Officer approval queue · approve/reject dialog · approval history · circular summary + key points + amendment banner · RAG chatbot (scoped + global, with citations) · dashboard (KPIs, charts, compliance tables) · audit log viewer · notification bell. Also: ERD diagram, architecture diagram, sequence diagram for the approval workflow, RAG pipeline diagram.

---

## 12. Requirements traceability (starter)
Map each thesis FR to where it's implemented (examples): FR-01 login → `auth/login`+JWT; FR-06–10 upload/extract → `circulars/upload`+pdf_extract; FR-11–16 summarize → AI pipeline/llm_summarizer; FR-18/20 classify → manual categories; FR-19/22–26 distribute/notify/remind → distribution service; FR-27–30 store/search/download/preview → circulars; FR-31–35 dashboard/reports → dashboard; FR-36–39 RAG chatbot → chatbot+vector_index; NFR-06 bcrypt; NFR-07 RBAC; NFR-08 offline AI; audit/non-repudiation → audit_log + viewer; governance (four-eyes) → submit/approve/reject.
