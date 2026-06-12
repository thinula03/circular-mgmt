# Phase 7 — Compliance Analytics Dashboard (Step-by-Step Log)

**Project:** Smart Circular Summarization & Management System for Banking
**Author:** H.M.C. Hasanthi (CT/2020/055) · CTEC 43018
**Goal of Phase 7:** give managers a real-time compliance dashboard (WF-04) — overall
and per-department metrics, per-employee tracking, trend charts, AI performance figures,
and exportable PDF/CSV reports. This is the final feature phase: it completes FR-31–35,
so all 40 functional requirements are implemented.

**Requirements covered**
| FR | Requirement | Priority |
|----|-------------|----------|
| FR-31 | Real-time compliance overview (published/ack/overdue/pending per dept) | Must |
| FR-32 | Per-employee reading/acknowledgement status per circular | Must |
| FR-33 | Trend charts (volume, ack rate, category distribution) | Should |
| FR-34 | Export compliance reports as PDF or CSV | Should |
| FR-35 | AI performance metrics (processing time, ROUGE) | Could |

> Prerequisite: Phases 0–6 complete; published + distributed circulars with
> acknowledgements exist. MySQL (XAMPP) running.

---

## Step 1 — Analytics endpoints (FR-31, 32, 33, 35)

Rewrote `backend/app/blueprints/dashboard.py` (all routes Manager/Administrator only).
SQLAlchemy aggregate helpers (`func.sum` + `case`) are reused across the queries.

- `GET /api/dashboard/overview` — totals (published, acknowledged, pending, overdue),
  overall acknowledgement rate, and a **per-department** breakdown (FR-31).
- `GET /api/dashboard/trends` — category distribution, acknowledgement-status split, and
  monthly published volume via `DATE_FORMAT` (FR-33).
- `GET /api/dashboard/circulars` — per published circular: acknowledged / total / overdue
  counts and rate (FR-32).
- `GET /api/dashboard/circulars/<id>/acknowledgements` — per-employee status for one
  circular (FR-32 drilldown).
- `GET /api/dashboard/ai-performance` — number of real summaries, average processing
  time, average ROUGE (null until reference summaries are added), and models used (FR-35).

---

## Step 2 — Report export (FR-34)

Added two export endpoints to the same blueprint:

- `GET /api/dashboard/export.csv` — builds the compliance report with the native `csv`
  module and returns it as a downloadable file.
- `GET /api/dashboard/export.pdf` — renders the same report to a PDF with **PyMuPDF**
  (already a dependency), so no new library is needed.

**Verify the backend imports cleanly:**

```powershell
cd backend
& ".venv\Scripts\python.exe" -c "from app import create_app; create_app(); print('IMPORT OK')"
cd ..
```

---

## Step 3 — Live backend tests

**Start MySQL (XAMPP) and the backend:**

```powershell
cd backend
& ".venv\Scripts\python.exe" run.py        # http://127.0.0.1:5000
cd ..
```

**1) Overview + trends + AI performance:**

```powershell
$base = "http://127.0.0.1:5000/api"
$mgr = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"manager","password":"password123"}' -ContentType "application/json"
$h = @{ Authorization = "Bearer $($mgr.access_token)" }

$o = Invoke-RestMethod -Uri "$base/dashboard/overview" -Headers $h
"published=$($o.published) ack=$($o.acknowledged) pending=$($o.pending) overdue=$($o.overdue) rate=$($o.ack_rate)%"
$o.by_department | ForEach-Object { "$($_.department): $($_.acknowledged)/$($_.total) ($($_.rate)%)" }

Invoke-RestMethod -Uri "$base/dashboard/ai-performance" -Headers $h
```

Result: `published=3 ack=2 pending=2 overdue=3 rate=50%`; per-department Compliance 0/2,
Operations 2/2 (100%); AI performance = 2 summaries, avg ~87 s, `facebook/bart-large-cnn`.

**2) Per-employee tracking (FR-32):**

```powershell
Invoke-RestMethod -Uri "$base/dashboard/circulars/3/acknowledgements" -Headers $h | ForEach-Object { "$($_.user): $($_.status)$(if($_.is_late){' LATE'})" }
```

**3) CSV + PDF export (FR-34):**

```powershell
Invoke-WebRequest -Uri "$base/dashboard/export.csv" -Headers $h -OutFile "$env:TEMP\report.csv"
Get-Content "$env:TEMP\report.csv" | Select-Object -First 3

Invoke-WebRequest -Uri "$base/dashboard/export.pdf" -Headers $h -OutFile "$env:TEMP\report.pdf"
[System.IO.File]::ReadAllBytes("$env:TEMP\report.pdf")[0..3]   # -> 37 80 68 70  (%PDF)
```

Both files download successfully (CSV with a header row + one line per circular; the PDF
opens as a valid document).

---

## Step 4 — WF-04 dashboard (frontend)

- `frontend/src/components/BarChart.jsx` — a small dependency-free horizontal bar chart
  (avoids adding a charting library).
- `frontend/src/pages/ManagerDashboard.jsx` — the full WF-04 screen:
  - **KPI cards** (published / acknowledged / pending / overdue) + an overall
    acknowledgement-rate bar (FR-31).
  - **Charts**: category distribution and acknowledgement-status (FR-33).
  - **Compliance by department** table (FR-31).
  - **Circular compliance** table with an expandable **per-employee drilldown** (FR-32).
  - **AI summarization performance** card (FR-35).
  - **Export CSV / Export PDF** buttons (authenticated blob download, FR-34).

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

Logged in as **manager** → **Compliance** screen:
1. KPI cards show Published 3, Acknowledged 2, Pending 2, Overdue 3; ack-rate bar = 50%.
2. Category and acknowledgement-status charts render.
3. Department table: Compliance 0/2 (0%), Operations 2/2 (100%).
4. Circular compliance table — clicking **Employees** expands the per-employee status
   (e.g. 07/2024: Compliance Manager Unread-late, Branch Employee Acknowledged-late).
5. AI performance card: 2 summaries, 87.31 s avg, `facebook/bart-large-cnn`.
6. Export buttons download the CSV/PDF. No console errors.

---

## Phase 7 outcome

| Step | Deliverable | Status |
|------|-------------|--------|
| 1 | Analytics endpoints (overview/trends/compliance/AI) | ✅ |
| 2 | CSV + PDF export endpoints (FR-34) | ✅ |
| 3 | Backend tests: metrics, tracking, exports | ✅ |
| 4 | WF-04 dashboard + bar charts | ✅ |
| 5 | Browser verification | ✅ |

**Result:** managers get a live compliance picture — overall and per-department rates,
per-circular and per-employee acknowledgement status, trend charts, AI performance, and
downloadable PDF/CSV reports. With this, **all functional requirements FR-01–FR-40 are
implemented** across the seven phases.

> Note: ROUGE (FR-35) shows `—` because it needs human reference summaries; the metric is
> wired and will populate once a reference set / evaluation harness is added. Charts use a
> lightweight custom bar component to avoid an extra frontend dependency.
