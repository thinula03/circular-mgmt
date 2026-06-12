# Phase 0 — Project Setup & Environment (Step-by-Step Log)

**Project:** Smart Circular Summarization & Management System for Banking
**Author:** H.M.C. Hasanthi (CT/2020/055) · CTEC 43018
**Goal of Phase 0:** stand up the full development environment — backend, database,
frontend, and AI models — and verify everything works end-to-end before building features.

**Environment used**
- OS: Windows 11 · Shell: PowerShell
- Python 3.10.8 · Node.js 24 / npm 11
- MySQL: MariaDB 10.4 (bundled with **XAMPP**) on `localhost:3306`, user `root`, empty password

> All commands below are run from the project root unless a `cd` is shown:
> `D:\university\academic\4th year\1st semester\research CTEC 43018\cicular-management`

---

## Step 1 — Repository & folder structure

Created the two-part layout and config files:

```
cicular-management/
├── backend/      (Flask API)
├── frontend/     (React app)
├── .gitignore
├── .env.example
└── README.md
```

Key files authored: `.gitignore` (ignores venv, node_modules, `.env`, `model_cache/`,
uploads), `.env.example` (config template), `README.md` (run instructions).

---

## Step 2 — Flask backend skeleton

Authored the backend package (no commands — source files):

```
backend/
├── app/
│   ├── __init__.py        # application factory create_app()
│   ├── config.py          # env-driven config (loads .env)
│   ├── extensions.py      # db (SQLAlchemy), jwt, cors
│   ├── models/            # 11 ORM models = the 11 ERD tables
│   ├── blueprints/        # auth, circulars, summaries, dashboard, chatbot
│   ├── ai/                # NLPPipeline interface + AIEngine, ChatbotService, VectorIndex
│   └── services/          # security (bcrypt/RBAC), audit, pdf_extract
├── migrations/001_init.sql
├── requirements.txt
├── run.py                 # dev entry point
└── seed.py                # demo data
```

---

## Step 3 — MySQL database & schema

**Verify MySQL is reachable** (XAMPP must be started first):

```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "SELECT VERSION();"
# -> 10.4.32-MariaDB
```

**Create the database + all 11 tables** from the migration script:

```powershell
Get-Content "backend\migrations\001_init.sql" -Raw | & "C:\xampp\mysql\bin\mysql.exe" -u root
```

**Confirm 11 tables were created:**

```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "USE circular_management; SHOW TABLES;"
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='circular_management';"
# -> 11
```

The 11 tables: `users, departments, circulars, summaries, circular_departments,
acknowledgements, classifications, notifications, audit_log, chat_log, vector_index_metadata`.

**Point the backend at MySQL** — created `backend/.env`:

```ini
DATABASE_URL=mysql+pymysql://root:@localhost:3306/circular_management
```

---

## Step 4 — Python virtual environment & core dependencies

**Create the virtual environment and upgrade pip:**

```powershell
python -m venv "backend\.venv"
& "backend\.venv\Scripts\python.exe" -m pip install --upgrade pip
```

**Install the core (non-AI) dependencies:**

```powershell
& "backend\.venv\Scripts\python.exe" -m pip install `
  Flask==3.0.3 Flask-SQLAlchemy==3.1.1 Flask-JWT-Extended==4.6.0 Flask-Cors==4.0.1 `
  python-dotenv==1.0.1 PyMySQL==1.1.1 bcrypt==4.2.0 PyMuPDF==1.24.10
```

**Verify Flask connects to MySQL and `/health` returns 200** (via `backend/verify_setup.py`):

```powershell
cd backend
& ".venv\Scripts\python.exe" verify_setup.py
# -> HEALTH: 200 {'database': 'mysql+pymysql', ...}
# -> TABLES_IN_DB: 11
cd ..
```

> Bug fixed here: `.env` was being read *after* the config object was built, so it
> fell back to SQLite. Moved `load_dotenv()` to the top of `config.py` so MySQL is used.

---

## Step 5 — React + Tailwind frontend (Teal + Slate theme)

Authored the Vite + React project under `frontend/` (package.json, vite.config.js,
tailwind.config.js with the Teal `#0E7C7B` + Slate theme, 5 page screens, Axios client,
AuthContext, router with RBAC guards).

**Install dependencies:**

```powershell
cd frontend
npm install
```

**Verify it builds:**

```powershell
npm run build
# -> 93 modules transformed, built successfully
```

**Run the dev server:**

```powershell
npm run dev
# -> http://localhost:5173
cd ..
```

The 5 screens: WF-01 Login, WF-02 Employee dashboard, WF-03 Summary + RAG chat,
WF-04 Manager compliance, WF-05 Admin upload.

---

## End-to-end demo (auth → Flask → MySQL)

**Seed demo data into MySQL:**

```powershell
cd backend
& ".venv\Scripts\python.exe" seed.py
# -> 3 departments, 3 users (admin/manager/employee), 1 sample circular
```

**Start the backend:**

```powershell
& ".venv\Scripts\python.exe" run.py     # http://127.0.0.1:5000
cd ..
```

**Test login + an authenticated API call:**

```powershell
$body = '{"username":"employee","password":"password123"}'
$r = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/auth/login" -Method Post -Body $body -ContentType "application/json"
$h = @{ Authorization = "Bearer $($r.access_token)" }
Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/circulars" -Headers $h
# -> returns the seeded circular 03/2024
```

Then logging in through the browser (employee / password123) loads the WF-02 dashboard
with **zero console errors**.

**Demo accounts** (password `password123`): `admin` (Administrator), `manager` (Manager),
`employee` (Employee).

---

## Step 6 — AI libraries & model downloads

**Install the AI libraries** (CPU build of PyTorch):

```powershell
& "backend\.venv\Scripts\python.exe" -m pip install `
  torch==2.4.1 transformers==4.44.2 spacy==3.7.6 `
  sentence-transformers==3.1.1 faiss-cpu==1.8.0 numpy==1.26.4
```

**Verify the libraries import:**

```powershell
& "backend\.venv\Scripts\python.exe" -c "import torch, transformers, spacy, sentence_transformers, faiss; print(torch.__version__)"
# -> 2.4.1+cpu
```

**Download the spaCy model:**

```powershell
cd backend
& ".venv\Scripts\python.exe" -m spacy download en_core_web_sm
```

**Download the Hugging Face models** into a project-local cache (`backend/model_cache/`)
using `backend/download_models.py`:

```powershell
& ".venv\Scripts\python.exe" download_models.py
cd ..
```

Models downloaded (~3 GB): `bert-base-uncased`, `facebook/bart-large-cnn`,
`sshleifer/distilbart-cnn-12-6` (fallback), `sentence-transformers/all-MiniLM-L6-v2`.

> Two Windows-specific issues fixed in `download_models.py`:
> 1. Apple **CoreML** `.mlpackage` files have paths longer than Windows' 260-char limit →
>    excluded coreml/onnx/tf/flax formats via `ignore_patterns`.
> 2. The **Xet** storage backend timed out → set `HF_HUB_DISABLE_XET=1` to use the standard CDN.

---

## Step 7 — Verify the AI stack works offline (NFR-08)

Ran `backend/verify_ai.py`, which forces offline mode (`HF_HUB_OFFLINE=1`) and loads
every model from the local cache:

```powershell
cd backend
& ".venv\Scripts\python.exe" verify_ai.py
cd ..
```

Output confirmed all models run locally with **no internet**:
- spaCy NER extracted entities (ORG, GPE, DATE, MONEY…)
- BERT tokenizer + model loaded
- **BART produced a real abstractive summary** of a sample circular
- Sentence-BERT produced a 384-dimension embedding

---

## How to run the whole system (quick reference)

```powershell
# 1. Start MySQL in the XAMPP Control Panel (start the "MySQL" module)

# 2. Backend
cd backend
& ".venv\Scripts\python.exe" run.py          # http://127.0.0.1:5000

# 3. Frontend (new terminal)
cd frontend
npm run dev                                    # http://localhost:5173

# 4. Open http://localhost:5173 and sign in with employee / password123
```

---

## Phase 0 outcome

| Step | Deliverable | Status |
|------|-------------|--------|
| 1 | Repo & folder structure | ✅ |
| 2 | Flask backend skeleton (11 models, 5 blueprints, AI layer) | ✅ |
| 3 | MySQL database + 11 tables | ✅ |
| 4 | venv + core deps; Flask ↔ MySQL verified | ✅ |
| 5 | React + Tailwind themed frontend (5 screens) | ✅ |
| 6 | AI libraries + 4 models downloaded | ✅ |
| 7 | AI stack verified running offline | ✅ |

The environment is ready. The AI engine currently runs as a **stub** (`USE_REAL_MODELS`
flags in `backend/app/ai/`); the real models are wired in during Phase 3 (summarization)
and Phase 6 (RAG chatbot).
