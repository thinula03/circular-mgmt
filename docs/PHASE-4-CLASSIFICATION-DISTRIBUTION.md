# Phase 4 — Classification & Distribution (Step-by-Step Log)

**Project:** Smart Circular Summarization & Management System for Banking
**Author:** H.M.C. Hasanthi (CT/2020/055) · CTEC 43018
**Goal of Phase 4:** when a circular is published, automatically route it to the
relevant departments based on its compliance classification, create an
acknowledgement record for every recipient, send in-app + email notifications, set an
acknowledgement deadline, and support reminders and manual re-classification.

**Requirements covered**
| FR | Requirement | Priority |
|----|-------------|----------|
| FR-18 | Auto-classify into compliance categories | Must |
| FR-19 | Route each circular to relevant departments | Must |
| FR-20 | Compliance officer can override the classification | Should |
| FR-21 | Priority tagging (High/Medium/Low) | Should |
| FR-22 | In-app notifications to relevant employees | Must |
| FR-23 | Email notification containing the summary | Should |
| FR-24 | Employees acknowledge receipt/reading | Must |
| FR-25 | Acknowledgement deadline; overdue flagged | Must |
| FR-26 | Reminders for un-acknowledged circulars | Should |

> Prerequisite: Phases 0–3 complete; at least one published circular. MySQL (XAMPP) running.

---

## Step 1 — Distribution service (FR-19, 22, 23, 25)

New file `backend/app/services/distribution.py` with two functions:

- `route_and_notify(circular)` —
  1. reads the circular's categories and maps them to departments via `CATEGORY_ROUTING`
     (e.g. Anti-Money Laundering → Compliance + Operations; Technology Risk → IT;
     General → all departments) (FR-19);
  2. records the routing in the `circular_departments` junction table;
  3. for every active Employee/Manager in those departments, creates an
     `Acknowledgement` (FR-24), an in-app `Notification` (FR-22), and "sends" an email
     containing the summary (FR-23);
  4. returns `{departments, recipient_count}`.

- `run_reminders(window_hours=24)` — for circulars whose deadline is within 24 hours or
  already passed, notifies/emails anyone who hasn't acknowledged and flags overdue
  acknowledgements as `is_late` (FR-25, FR-26).

---

## Step 2 — Wire distribution + deadline into publish (FR-25)

Edited `backend/app/blueprints/circulars.py`:
- The summarize endpoint now sets `ack_deadline = now + ack_days` (default 7, FR-25),
  and after publishing calls `distribution.route_and_notify(circular)`.
- Added `PATCH /api/circulars/<id>/classification` (Manager/Administrator) to override
  the classification and re-route if the circular is already published (FR-20).
- Added `POST /api/circulars/reminders/run` (Manager/Administrator) to trigger
  reminders (FR-26).

Added `backend/app/blueprints/notifications.py` (registered in `blueprints/__init__.py`):
`GET /api/notifications`, `POST /api/notifications/<id>/read`,
`POST /api/notifications/read-all` (FR-22).

**Verify the new routes are registered:**

```powershell
cd backend
& ".venv\Scripts\python.exe" -c "from app import create_app; a=create_app(); print([str(r) for r in a.url_map.iter_rules() if 'notifications' in str(r) or 'reminders' in str(r) or 'classification' in str(r)])"
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

**1) Route a published circular via a classification override** (FR-19, FR-20, FR-22):

```powershell
$base = "http://127.0.0.1:5000/api"
$admin = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"admin","password":"password123"}' -ContentType "application/json"
$h = @{ Authorization = "Bearer $($admin.access_token)" }

# Circular 3 (07/2024) is published — override its category to AML, which re-routes it
$ov = Invoke-RestMethod -Uri "$base/circulars/3/classification" -Method Patch -Headers $h -Body '{"categories":["Anti-Money Laundering"]}' -ContentType "application/json"
"routed to: $($ov.distribution.departments -join ', ') | recipients: $($ov.distribution.recipient_count)"
```

Result: `routed to: Compliance, Operations | recipients: 3`.

**2) Confirm the employee received in-app notifications** (FR-22):

```powershell
$emp = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"employee","password":"password123"}' -ContentType "application/json"
$eh = @{ Authorization = "Bearer $($emp.access_token)" }
$notif = Invoke-RestMethod -Uri "$base/notifications" -Headers $eh
"unread: $($notif.unread) | latest: $($notif.items[0].message)"
```

**3) Reminders + overdue flag** (FR-25, FR-26) — simulate an overdue circular:

```powershell
# Force circular 3's deadline into the past
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "USE circular_management; UPDATE circulars SET ack_deadline = DATE_SUB(NOW(), INTERVAL 1 DAY) WHERE id=3;"

$rem = Invoke-RestMethod -Uri "$base/circulars/reminders/run" -Method Post -Headers $h
"reminded: $($rem.reminded) | overdue flagged: $($rem.overdue)"
```

Result: `reminded: 3 | overdue flagged: 3`.

**4) Acknowledge after the deadline → marked late** (FR-24, FR-25):

```powershell
$ack = Invoke-RestMethod -Uri "$base/summaries/3/acknowledge" -Method Post -Headers $eh
"status: $($ack.status) | is_late: $($ack.is_late)"
```

Result: `status: Acknowledged | is_late: True`.

**5) Confirm emails were 'sent'** (FR-23 — written to the dev outbox):

```powershell
Select-String -Path "backend\outbox.log" -Pattern '^Subject:' | Select-Object -Last 4 | ForEach-Object { $_.Line }
```

---

## Step 4 — Frontend: notification bell + distribution UI

- `frontend/src/components/NotificationBell.jsx` — a header bell with an unread-count
  badge and a dropdown listing notifications (with timestamps) and a **Mark all read**
  action; refreshes every minute (FR-22).
- `frontend/src/components/Layout.jsx` — placed the bell in the top bar for all roles.
- `frontend/src/pages/AdminUpload.jsx` — added an **"Acknowledge within (days)"** input
  (FR-25) passed to the summarize call, and a **distribution result** banner
  ("Routed to Compliance, Operations — 3 recipients notified", FR-19).

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

Logged in as **employee** → the bell shows a **3** badge; opening it lists the new
circular notification, the reminder, and the seeded notification — no console errors.
(Administrators are not circular recipients, so their bell stays empty by design.)

---

## Phase 4 outcome

| Step | Deliverable | Status |
|------|-------------|--------|
| 1 | Distribution service: routing, acks, notifications, email, reminders | ✅ |
| 2 | Publish wiring + deadline + override + reminders + notifications API | ✅ |
| 3 | Backend tests: route (3 recipients), reminders (3 overdue), late ack | ✅ |
| 4 | Notification bell + deadline input + distribution banner | ✅ |
| 5 | Browser verification (employee bell = 3 unread) | ✅ |

**Result:** publishing a circular now auto-routes it to the correct departments, creates
acknowledgements, and notifies recipients in-app and by email; managers can override the
classification and send reminders; overdue acknowledgements are flagged. The
acknowledgement *button* for employees is wired into the WF-03 summary view in Phase 5.

> Test note: circular 07/2024's deadline was set to the past via SQL to exercise the
> reminder/overdue path. **Recipients** = active Employees/Managers in routed departments.
