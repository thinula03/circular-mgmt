# Phase 3 — AI Summarization Engine (Step-by-Step Log)

**Project:** Smart Circular Summarization & Management System for Banking
**Author:** H.M.C. Hasanthi (CT/2020/055) · CTEC 43018
**Goal of Phase 3:** turn the stub AI into the **real three-stage NLP pipeline** —
spaCy preprocessing & NER, BERT extractive sentence selection, and BART abstractive
summarization — running fully offline on the local server, and expose it through an
endpoint that summarizes a stored circular.

**Requirements covered**
| FR | Requirement | Priority |
|----|-------------|----------|
| FR-11 | spaCy preprocessing + NER (dates, amounts, regulatory refs) | Must |
| FR-12 | BERT sentence embeddings → select top-K sentences | Must |
| FR-13 | BART abstractive summary from the selected sentences | Must |
| FR-14 | Configurable summary length (default 150–250 words) | Must |
| FR-15 | Display key named entities as highlighted tags | Should |
| FR-16 | distilbart fallback for resource-constrained environments | Should |
| FR-17 | Real-time processing status indicator | Should |

> Prerequisite: Phases 0–2 complete; AI models already downloaded to
> `backend/model_cache/` (Phase 0). MySQL (XAMPP) running.

---

## Step 1 — Implement the real pipeline (FR-11–14, 16)

Rewrote `backend/app/ai/pipeline.py` so `AIEngine` implements the real three stages
and sets `USE_REAL_MODELS = True`. Key points:

- **Offline loading** — models load from `backend/model_cache/hub` with
  `local_files_only=True` and `HF_HUB_OFFLINE=1`, so no network call is made (NFR-08).
- **Lazy singletons** — heavy libraries (torch, transformers, spaCy) are imported
  inside loader methods, and models are cached on the instance, so the app starts fast
  and models load only once on first summarization.
- **Stage 1 (spaCy)** — `extract_entities()` keeps DATE / MONEY / PERCENT / ORG / GPE /
  LAW / CARDINAL entities plus a regex for explicit circular references.
- **Stage 2 (BERT)** — `_extractive_select()` embeds sentences (mean-pooled
  `bert-base-uncased`), scores each by centrality to the document, and keeps the
  top-K (K scaled to the target length).
- **Stage 3 (BART)** — `_abstractive()` runs `facebook/bart-large-cnn`, falling back to
  `sshleifer/distilbart-cnn-12-6` if the primary model fails to load (FR-16).

**Test the pipeline standalone** (loads the models and summarizes a sample):

```powershell
cd backend
& ".venv\Scripts\python.exe" -c "from app.ai.pipeline import AIEngine; e=AIEngine({}); r=e.summarize('CENTRAL BANK OF SRI LANKA. Circular No. 05/2024. All licensed commercial banks shall maintain a minimum capital adequacy ratio of 12.5 percent. Banks must submit quarterly Basel III compliance reports.', target_words=120); print(r.bart_model, r.processing_seconds, 's'); print(r.summary_text); print(r.entities)"
cd ..
```

Result: a real abstractive summary plus spaCy entities. (First run ~70 s on CPU
because it loads BART; later runs reuse the cached model.)

---

## Step 2 — Summarize endpoint (FR-14, FR-17, FR-18)

Added `POST /api/circulars/<id>/summarize` to
`backend/app/blueprints/circulars.py` (Administrator-only). Flow:

1. Set the circular's `status = "processing"` (so the UI can show progress, FR-17).
2. Run `engine.summarize(text, target_words)` (FR-14, bounded 80–300 words).
3. Save a `Summary` row (text, entities, model names, processing time).
4. Auto-classify the compliance category and save a `Classification` (FR-18).
5. Set `status = "published"`; on error set `status = "failed"`.

**Verify the route is registered:**

```powershell
cd backend
& ".venv\Scripts\python.exe" -c "from app import create_app; a=create_app(); print([str(r) for r in a.url_map.iter_rules() if 'summarize' in str(r)])"
cd ..
```

---

## Step 3 — Preprocessing fix (data quality)

The first live run produced a **hallucinated** summary because the test PDF's extracted
text had broken sentence boundaries (e.g. `05/2024Date:` with no spaces or periods),
so BART filled gaps with invented content.

Fix: added `_clean_text()` to the pipeline (FR-11 preprocessing) which re-inserts spaces
at glued word/number boundaries and collapses all whitespace, then applied it before
spaCy/BERT/BART. After this, summaries are faithful to the source.

---

## Step 4 — Live end-to-end test

**Start MySQL (XAMPP) and the backend:**

```powershell
cd backend
& ".venv\Scripts\python.exe" run.py        # http://127.0.0.1:5000
cd ..
```

**Generate a realistic CBSL circular PDF** (well-punctuated, ~1 page):

```powershell
$backend = "backend"
& "$backend\.venv\Scripts\python.exe" -c "import fitz; d=fitz.open(); p=d.new_page(); p.insert_textbox(fitz.Rect(60,60,540,760), 'CENTRAL BANK OF SRI LANKA\nCircular No. 07/2024 dated 15 May 2024.\n\nSubject: Enhanced Customer Due Diligence and Anti-Money Laundering Controls.\n\nAll licensed commercial banks are directed to strengthen their anti-money laundering procedures. Banks shall conduct enhanced due diligence for accounts where the monthly transaction value exceeds Rs. 5,000,000. Suspicious transaction reports shall be filed with the Financial Intelligence Unit within twenty-four hours. Each bank shall appoint a Compliance Officer and submit quarterly reports. Compliance must be confirmed by 30 June 2024.', fontsize=11, fontname=chr(34)+chr(34)); d.save(r'$backend\sample_circular.pdf'); d.close()"
```

**Upload it, then summarize** (uses `curl.exe` for the multipart upload):

```powershell
$base = "http://127.0.0.1:5000/api"
$admin = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"admin","password":"password123"}' -ContentType "application/json"
$tok = $admin.access_token ; $h = @{ Authorization = "Bearer $tok" }

$up = curl.exe -s -X POST "$base/circulars/upload" -H "Authorization: Bearer $tok" -F "file=@backend\sample_circular.pdf" -F "circular_number=07/2024" -F "title=Enhanced CDD and AML Controls" -F "issue_date=2024-05-15" -F "priority=High" | ConvertFrom-Json

# Summarize (allow a long timeout — first run loads BART)
$r = Invoke-RestMethod -Uri "$base/circulars/$($up.circular.id)/summarize?target_words=130" -Method Post -Headers $h -TimeoutSec 320
$r.summary.summary_text
$r.classifications | ForEach-Object { $_.category }
```

Result (status `published`):
- Real `facebook/bart-large-cnn` summary, faithful to the circular (no hallucination).
- Auto-classified **Anti-Money Laundering**.
- ~95 s including first-time model load (within NFR-02's 120 s; later runs reuse the
  in-memory model).

**Confirm the summary persisted in MySQL:**

```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "USE circular_management; SELECT c.circular_number, s.bart_model, s.word_count, s.processing_seconds FROM summaries s JOIN circulars c ON c.id=s.circular_id;"
```

---

## Step 5 — Frontend: trigger + display (FR-15, FR-17)

- `frontend/src/components/EntityTags.jsx` — renders the spaCy named entities as
  colour-coded, highlighted tags (FR-15).
- `frontend/src/pages/AdminUpload.jsx` — after a successful upload, a
  **"✨ Generate AI summary"** button calls the summarize endpoint, shows a live
  **"Summarizing… (spaCy → BERT → BART)"** spinner (FR-17), then displays the summary,
  the compliance category, the model name / word count / time, and the entity tags.

**Verify the frontend builds:**

```powershell
cd frontend
npm run build        # -> built successfully
cd ..
```

---

## Phase 3 outcome

| Step | Deliverable | Status |
|------|-------------|--------|
| 1 | Real spaCy→BERT→BART pipeline, offline (FR-11–14,16) | ✅ |
| 2 | `POST /circulars/<id>/summarize` endpoint (FR-14,17,18) | ✅ |
| 3 | `_clean_text` preprocessing fix (faithful summaries) | ✅ |
| 4 | Live test: 05/2024 & 07/2024 summarized + stored in MySQL | ✅ |
| 5 | Summary trigger + NER tags UI (FR-15,17) | ✅ |

**Result:** uploaded circulars are summarized by the real three-stage NLP pipeline,
entirely on the local server. Each `Summary` stores the abstractive text, the spaCy
entities, the model names, and the processing time — ready to be surfaced to employees
in Phase 5 (summary view) and queried by the RAG chatbot in Phase 6.

> Verification note: the upload→summarize **click-through** can't be automated by the
> preview tools (browser file-picker), so it was verified via the API + MySQL. The full
> UI flow can be done manually with `backend\sample_circular.pdf`.

**Performance:** first summarization ~80–95 s (includes one-time model load); the model
singleton stays in memory, so subsequent summaries are much faster.
