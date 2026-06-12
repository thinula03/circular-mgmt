# Phase 1 — Authentication & RBAC Hardening (Step-by-Step Log)

**Project:** Smart Circular Summarization & Management System for Banking
**Author:** H.M.C. Hasanthi (CT/2020/055) · CTEC 43018
**Goal of Phase 1:** strengthen the login/role system from Phase 0 — add password
reset, a 30-minute inactive-session timeout, and an admin screen to create users and
assign roles & departments.

**Requirements covered**
| FR | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Secure username/password login | Must |
| FR-02 | Three roles (Administrator / Manager / Employee) with distinct access | Must |
| FR-03 | Auto-terminate inactive sessions after 30 minutes | Must |
| FR-04 | Password reset via registered email | Should |
| FR-05 | Admin assigns users to a department | Must |

> Prerequisite: Phase 0 complete, MySQL (XAMPP) running. Project root:
> `D:\university\academic\4th year\1st semester\research CTEC 43018\cicular-management`

---

## Step 1 — Password reset backend (FR-04)

New files authored:
- `backend/app/services/tokens.py` — signed, time-limited reset tokens using
  **itsdangerous** (a Flask dependency), so **no new database table** is needed and the
  documented 11-table ERD stays unchanged. Token carries the user id, expires in 30 min.
- `backend/app/services/email.py` — email "delivery". No SMTP is configured for the
  prototype, so it logs the message and appends it to `backend/outbox.log`.

Extended `backend/app/blueprints/auth.py` with three endpoints:
- `POST /api/auth/forgot-password` — generates a reset link, "emails" it, and (in debug)
  returns the link as `dev_reset_url`. Always returns a generic message so it never
  reveals which emails exist.
- `POST /api/auth/reset-password` — validates the token and sets a new bcrypt password.
- `POST /api/auth/change-password` — logged-in user changes their own password.

---

## Step 2 — Admin user management backend (FR-02, FR-05)

New file `backend/app/blueprints/users.py` (all routes **Administrator-only**, RBAC):

| Method & path | Purpose |
|---------------|---------|
| `GET /api/users` | List all users |
| `POST /api/users` | Create user + assign role & department |
| `PATCH /api/users/<id>` | Update role / department / name |
| `POST /api/users/<id>/deactivate` | Soft delete (`is_active = False`) |
| `POST /api/users/<id>/activate` | Re-activate |
| `GET /api/users/departments` | Department list for the dropdown |

Registered the blueprint in `backend/app/blueprints/__init__.py`.

**Verify the backend imports and the new routes are registered:**

```powershell
cd backend
& ".venv\Scripts\python.exe" -c "from app import create_app; app=create_app(); print('IMPORT OK'); print([str(r) for r in app.url_map.iter_rules() if '/api/users' in str(r) or '/api/auth' in str(r)])"
cd ..
```

---

## Step 3 — Live backend tests

**Start the backend** (ensure XAMPP MySQL is running first):

```powershell
cd backend
& ".venv\Scripts\python.exe" run.py        # http://127.0.0.1:5000
cd ..
```

**Test admin user management** (login as admin, list departments, create a user):

```powershell
$base = "http://127.0.0.1:5000/api"
$admin = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"admin","password":"password123"}' -ContentType "application/json"
$h = @{ Authorization = "Bearer $($admin.access_token)" }

# Departments (for the assignment dropdown)
$deps = Invoke-RestMethod -Uri "$base/users/departments" -Headers $h
$deps | ForEach-Object { $_.name }

# Create a Manager assigned to the first department
$newUser = '{"username":"tharindu","email":"tharindu@bank.lk","full_name":"Tharindu Perera","role":"Manager","department_id":'+$deps[0].id+',"password":"password123"}'
Invoke-RestMethod -Uri "$base/users" -Method Post -Headers $h -Body $newUser -ContentType "application/json"

# List users
Invoke-RestMethod -Uri "$base/users" -Headers $h | ForEach-Object { "$($_.username) - $($_.role)" }
```

Result: created `tharindu` (Manager, Compliance); user list grew to 4.

**Test the password-reset flow** (request link → reset → log in with new password):

```powershell
$fp = Invoke-RestMethod -Uri "$base/auth/forgot-password" -Method Post -Body '{"email":"tharindu@bank.lk"}' -ContentType "application/json"
$token = ($fp.dev_reset_url -split "token=")[1]
Invoke-RestMethod -Uri "$base/auth/reset-password" -Method Post -Body (@{ token=$token; password="newpass1234" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"tharindu","password":"newpass1234"}' -ContentType "application/json"
```

Result: `Password updated.` → re-login with the new password succeeded.

**Test RBAC** (an Employee must NOT reach the admin users list):

```powershell
$emp = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"employee","password":"password123"}' -ContentType "application/json"
$eh = @{ Authorization = "Bearer $($emp.access_token)" }
try { Invoke-RestMethod -Uri "$base/users" -Headers $eh } catch { "Blocked: $($_.Exception.Response.StatusCode.value__)" }
```

Result: **403 Forbidden** — RBAC enforced (NFR-07).

---

## Step 4 — Frontend: idle logout + session expiry (FR-03)

- `frontend/src/hooks/useIdleTimeout.js` — resets a 30-minute timer on any user
  activity (mouse, key, scroll, touch); fires a logout callback when it elapses.
- `frontend/src/components/Layout.jsx` — uses the hook: on idle it signs out and
  redirects to `/login?expired=1`.
- `frontend/src/pages/Login.jsx` — shows a banner for `?expired=1` ("session expired")
  and `?reset=1` ("password updated"), plus a **Forgot password?** link.

---

## Step 5 — Frontend: reset pages + admin Users screen

New pages:
- `frontend/src/pages/ForgotPassword.jsx` — email form; shows the dev reset link.
- `frontend/src/pages/ResetPassword.jsx` — reads `?token=`, sets a new password.
- `frontend/src/pages/Users.jsx` — admin screen: create-user form + table with inline
  role/department editors and activate/deactivate buttons.

Wiring:
- `frontend/src/App.jsx` — added public routes `/forgot-password`, `/reset-password`,
  and an Administrator-guarded `/users` route.
- `frontend/src/components/Layout.jsx` — added a **Users** nav link (Administrator only).

**Verify the frontend builds:**

```powershell
cd frontend
npm run build          # -> 97 modules transformed, built successfully
cd ..
```

---

## Step 6 — End-to-end browser verification

```powershell
# Backend (terminal 1)
cd backend ; & ".venv\Scripts\python.exe" run.py

# Frontend (terminal 2)
cd frontend ; npm run dev          # http://localhost:5173
```

Checked in the browser:
1. Logged in as **admin** → the **Users** nav link appears (it does not for manager/employee).
2. **User Management** screen lists all users with role + department dropdowns and
   activate/deactivate — no console errors.
3. **Forgot password** page → submitting an email shows the generic message and the dev
   reset link.

All checks passed.

---

## Phase 1 outcome

| Step | Deliverable | Status |
|------|-------------|--------|
| 1 | Password reset backend (tokens, email, 3 endpoints) | ✅ |
| 2 | Admin user-management blueprint (FR-02/05) | ✅ |
| 3 | Backend tests: user mgmt, reset flow, RBAC 403 | ✅ |
| 4 | 30-min idle logout + expiry notices (FR-03) | ✅ |
| 5 | Forgot/Reset pages + admin Users screen | ✅ |
| 6 | End-to-end browser verification | ✅ |

**Design note:** FR-05 is implemented as **single-department** assignment to match the
documented 11-table ERD (`users.department_id`). Moving to "one or more" departments would
add a 12th `user_departments` junction table — deferred unless required.

**Demo accounts** (password `password123`): `admin`, `manager`, `employee`
(plus `tharindu`, created during testing, password now `newpass1234`).
