# Phase 5 — Database, Search & Live Views (Step-by-Step Log)

**Project:** Smart Circular Summarization & Management System for Banking
**Author:** H.M.C. Hasanthi (CT/2020/055) · CTEC 43018
**Goal of Phase 5:** make the stored circulars and AI summaries visible in the app —
a live, role-scoped circular list with keyword search and filters (WF-02), and a full
summary view where employees read the AI summary, see the entities, download the
original PDF, and acknowledge the circular (WF-03).

**Requirements covered**
| FR | Requirement | Priority |
|----|-------------|----------|
| FR-27 | Store circulars, text, summaries, metadata in MySQL | Must |
| FR-28 | Keyword search across title, summary, category, dates | Must |
| FR-29 | Filter by date range, category, department, ack status | Must |
| FR-30 | Download the original PDF | Should |

> Prerequisite: Phases 0–4 complete; published + distributed circulars exist.
> MySQL (XAMPP) running.

---

## Step 1 — Role-scoped list with search & filters (FR-28, FR-29)

Rewrote `GET /api/circulars` in `backend/app/blueprints/circulars.py`:

- **Role scoping** — Employees see only circulars they have an acknowledgement for
  (i.e. routed to their department); Managers/Administrators see all. Each row is
  paired with the viewer's acknowledgement so the list can show `my_status`.
- **Keyword search (FR-28)** — matches the title, circular number, summary text, or
  category (`or_` across `Circular.title`, `Circular.summary.has(...)`,
  `Circular.classifications.any(...)`).
- **Filters (FR-29)** — `category`, ack `status`, `department_id`, and `date_from` /
  `date_to` on the issue date.

Also updated `GET /api/circulars/<id>`:
- On open, an **Unread** acknowledgement is marked **Read** (SD-02), and the response
  includes `my_status` / `my_ack`.

> Note: ordering uses `published_at DESC` (MySQL/MariaDB sorts NULLs last on DESC, so
> drafts fall to the bottom — `NULLS LAST` syntax is avoided because MariaDB 10.4 lacks it).

---

## Step 2 — PDF download (FR-30)

Added `GET /api/circulars/<id>/download` — returns the stored PDF via Flask `send_file`
with an attachment filename like `Circular_03-2024.pdf`, and writes an audit entry.

**Verify the routes import:**

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

> If MySQL is down, start it in the XAMPP Control Panel (or launch
> `C:\xampp\mysql\bin\mysqld.exe --defaults-file=C:\xampp\mysql\bin\my.ini`), then
> restart the backend so the connection pool is fresh.

**1) Role-scoped list + per-user status:**

```powershell
$base = "http://127.0.0.1:5000/api"
$emp = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"employee","password":"password123"}' -ContentType "application/json"
$eh = @{ Authorization = "Bearer $($emp.access_token)" }
(Invoke-RestMethod -Uri "$base/circulars" -Headers $eh) | ForEach-Object { "$($_.circular_number) | $($_.my_status) | [$($_.categories -join ',')]" }
```

Result: the employee sees only their two circulars (07/2024 Acknowledged, 03/2024 Unread).

**2) Search + admin scope:**

```powershell
# Employee search is limited to their own circulars
(Invoke-RestMethod -Uri "$base/circulars?q=capital" -Headers $eh) | ForEach-Object { $_.circular_number }   # -> (none)

# Admin sees all circulars
$admin = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"admin","password":"password123"}' -ContentType "application/json"
$ah = @{ Authorization = "Bearer $($admin.access_token)" }
"admin count: $((Invoke-RestMethod -Uri "$base/circulars" -Headers $ah).Count)"   # -> 3
```

**3) PDF download (FR-30) + mark-read-on-open (SD-02):**

```powershell
Invoke-WebRequest -Uri "$base/circulars/3/download" -Headers $eh -OutFile "$env:TEMP\dl.pdf"
[System.IO.File]::ReadAllBytes("$env:TEMP\dl.pdf")[0..3]   # -> 37 80 68 70  (%PDF)

# Opening an Unread circular marks it Read
(Invoke-RestMethod -Uri "$base/circulars/1" -Headers $eh).my_status   # -> Read
```

---

## Step 4 — Live WF-02 dashboard (frontend)

Rewrote `frontend/src/pages/EmployeeDashboard.jsx`:
- Fetches `/api/circulars` with `q`, `category`, `status` params.
- Search box + category + status dropdowns (filters refetch on change; search on submit).
- Table shows circular number, title, category chips, priority, and the colour-coded
  acknowledgement status (`StatusBadge`), with an **Open** link.
- Title reads **My Circulars** for employees, **All Circulars** for managers/admins.

---

## Step 5 — Live WF-03 summary view (frontend)

Rewrote `frontend/src/pages/CircularSummary.jsx`:
- Fetches the circular detail and renders the **AI summary**, the **NER entity tags**
  (`EntityTags`), the compliance categories, and metadata.
- **Acknowledge** button → `POST /api/summaries/<id>/acknowledge`; the status badge
  updates to **Acknowledged** (green) and the button disappears.
- **View original PDF** → authenticated blob download (sends the JWT, then saves the file).
- The right-hand chat panel remains a placeholder until Phase 6.

**Verify the frontend builds:**

```powershell
cd frontend
npm run build        # -> built successfully
cd ..
```

---

## Step 6 — Browser verification

```powershell
# Backend (terminal 1)
cd backend ; & ".venv\Scripts\python.exe" run.py
# Frontend (terminal 2)
cd frontend ; npm run dev          # http://localhost:5173
```

Logged in as **employee**:
1. **WF-02** lists the two assigned circulars with colour-coded status (07/2024
   Acknowledged/green, 03/2024 Read/amber) — search and filters work.
2. **WF-03** shows the AI summary, the entity tags (DATE/MONEY/REGULATION), the
   Acknowledge and View-PDF buttons.
3. Clicking **Acknowledge** flips the status to **Acknowledged** (green); no console errors.

**Confirm it persisted in MySQL:**

```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "USE circular_management; SELECT c.circular_number, u.username, a.status FROM acknowledgements a JOIN circulars c ON c.id=a.circular_id JOIN users u ON u.id=a.user_id ORDER BY a.circular_id;"
```

Result: employee = Acknowledged for 03/2024 and 07/2024; other recipients still Unread.

---

## Phase 5 outcome

| Step | Deliverable | Status |
|------|-------------|--------|
| 1 | Role-scoped list + search + filters (FR-28/29) | ✅ |
| 2 | PDF download endpoint (FR-30) | ✅ |
| 3 | Backend tests: scope, search, download, mark-read | ✅ |
| 4 | Live WF-02 dashboard | ✅ |
| 5 | Live WF-03 summary view + acknowledge | ✅ |
| 6 | Browser verification + MySQL persistence | ✅ |

**Result:** employees now see only the circulars assigned to them, search and filter the
list, open a circular to read the AI summary and entities, download the original PDF, and
acknowledge it — with the colour-coded status (red/amber/green) consistent across WF-02
and WF-03.

> Environment note: XAMPP MySQL stopped a couple of times during this phase; data persists
> (InnoDB), but keep MySQL running via the XAMPP Control Panel and restart the Flask backend
> after any MySQL bounce. The WF-03 chatbot panel is completed in Phase 6.
