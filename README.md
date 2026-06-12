# Smart Circular Summarization & Management System for Banking

Final-year research project (CTEC 43018) — H.M.C. Hasanthi, CT/2020/055.
An AI-driven web application that summarizes, classifies, distributes, and tracks
compliance of CBSL regulatory circulars, with a RAG-powered chatbot. All AI runs
locally (no external APIs) for data privacy.

## Stack
- **Backend:** Python Flask · SQLAlchemy · JWT · MySQL 8 / MariaDB
- **Frontend:** React + Vite + Tailwind CSS (Teal + Slate theme)
- **AI (Phase 3/6):** spaCy → BERT → BART summarization · Sentence-BERT + FAISS RAG

## Prerequisites
- Python 3.10+
- Node.js 18+
- MySQL 8 or MariaDB (XAMPP works) running on `localhost:3306`

## First-time setup

### 1. Database
Start MySQL (e.g. XAMPP Control Panel → start **MySQL**), then create the schema:
```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root < backend\migrations\001_init.sql
```
This creates the `circular_management` database with all 11 tables.

### 2. Backend
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt        # core deps (AI libs are commented-heavy; see note)
copy ..\.env.example .env              # then confirm DATABASE_URL points to MySQL
python seed.py                          # load demo users + sample circular
python run.py                           # serves http://127.0.0.1:5000
```
```bash / WSL / Git Bash
cd backend
source .venv/Scripts/activate
# ensure MySQL is running
python run.py
```
### 3. Frontend
```powershell
cd frontend
npm install
npm run dev                             # serves http://localhost:5173
```

Open http://localhost:5173 and sign in.

## Demo accounts (password: `password123`)
| Username   | Role          | Sees                                  |
|------------|---------------|---------------------------------------|
| `admin`    | Administrator | Circulars, Compliance, **Upload**     |
| `manager`  | Manager       | Circulars, **Compliance**             |
| `employee` | Employee      | Circulars only                        |

## Project status (phased build)
- **Phase 0 — Setup & environment:** ✅ structure, MySQL schema, Flask skeleton,
  React + Tailwind themed shell, end-to-end auth verified. (AI model downloads pending.)
- **Phase 1+** — auth hardening, upload + PDF extraction, AI summarization, classification
  & distribution, search, RAG chatbot, analytics dashboard. See `.claude/plans/`.

> Note: the AI engine currently runs as a lightweight **stub** (see `USE_REAL_MODELS`
> flags in `backend/app/ai/`). Real BERT/BART/FAISS models are wired in Phase 3/6.

## Layout
```
backend/    Flask API — app factory, 11 models, 5 blueprints, AI layer, migrations
frontend/   React app — 5 screens, Teal+Slate theme, Axios + JWT
```
