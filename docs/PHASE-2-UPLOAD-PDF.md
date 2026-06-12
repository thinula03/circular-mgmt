# Phase 2 — Circular Upload & PDF Extraction (Step-by-Step Log)

**Project:** Smart Circular Summarization & Management System for Banking
**Author:** H.M.C. Hasanthi (CT/2020/055) · CTEC 43018
**Goal of Phase 2:** let an administrator upload a CBSL circular PDF, then validate it,
extract its full text with PyMuPDF, capture its metadata, and detect duplicates —
building the working WF-05 upload screen.

**Requirements covered**
| FR | Requirement | Priority |
|----|-------------|----------|
| FR-06 | Admin can upload CBSL circulars in PDF format | Must |
| FR-07 | Extract full text from uploaded PDFs (PyMuPDF) | Must |
| FR-08 | Capture metadata: circular number, date, title, file size | Must |
| FR-09 | Validate files; reject non-PDF or files over 20 MB | Must |
| FR-10 | Detect & warn on duplicate circular numbers | Should |

> Prerequisite: Phases 0–1 complete, MySQL (XAMPP) running. Project root:
> `D:\university\academic\4th year\1st semester\research CTEC 43018\cicular-management`

---

## Step 1 — PDF extraction service (FR-07)

Updated `backend/app/services/pdf_extract.py` to add `extract_text_with_meta()`,
which returns both the full text and the page count, and raises `ValueError` if the
file is not a readable PDF.

---

## Step 2 — Upload endpoint (FR-06, FR-08, FR-09, FR-10)

Rewrote `POST /api/circulars/upload` in `backend/app/blueprints/circulars.py`.
It is **Administrator-only** (RBAC) and runs this pipeline:

1. Validate a file is present and ends in `.pdf` (FR-09).
2. Read metadata from the form: circular number, title, issue date, priority (FR-08).
3. Reject if a circular with the same number already exists → **409** (FR-10).
4. Save the PDF to `backend/uploads/` with a unique name.
5. Extract text + page count with PyMuPDF (FR-07).
6. Create the `Circular` record (`status = "uploaded"`) and write an audit entry.

Also added a **413 handler** in `backend/app/__init__.py` so files over 20 MB return a
clean JSON error instead of an HTML page (FR-09).

**Verify the backend imports cleanly:**

```powershell
cd backend
& ".venv\Scripts\python.exe" -c "from app import create_app; create_app(); print('IMPORT OK')"
cd ..
```

---

## Step 3 — Create a sample PDF for testing

Generated a small CBSL-style circular PDF with PyMuPDF:

```powershell
$backend = "backend"
& "$backend\.venv\Scripts\python.exe" -c "import fitz; d=fitz.open(); p=d.new_page(); p.insert_text((72,72), 'CENTRAL BANK OF SRI LANKA\nCircular No. 05/2024\nDate: 01/05/2024\n\nSubject: Capital Adequacy Requirements for Licensed Banks\n\nAll licensed commercial banks shall maintain a minimum capital adequacy ratio of 12.5 percent...', fontsize=11); d.save(r'$backend\sample_circular.pdf'); d.close(); print('PDF created')"
```

---

## Step 4 — Live backend tests (upload, duplicate, non-PDF)

**Start MySQL (XAMPP) and the backend:**

```powershell
cd backend
& ".venv\Scripts\python.exe" run.py        # http://127.0.0.1:5000
cd ..
```

> Note: file uploads are `multipart/form-data`. Windows PowerShell 5.1 has no
> `Invoke-RestMethod -Form`, so we use the bundled **`curl.exe`** for the upload calls.

**1) Upload a real PDF** (expect 201 with extracted text + metadata):

```powershell
$base = "http://127.0.0.1:5000/api"
$admin = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body '{"username":"admin","password":"password123"}' -ContentType "application/json"
$tok = $admin.access_token

curl.exe -s -X POST "$base/circulars/upload" `
  -H "Authorization: Bearer $tok" `
  -F "file=@backend\sample_circular.pdf" `
  -F "circular_number=05/2024" `
  -F "title=Capital Adequacy Requirements" `
  -F "issue_date=2024-05-01" `
  -F "priority=High"
```

Result (201): circular stored (`status = uploaded`), extraction reported
`page_count = 1`, `word_count = 33`, plus a text preview.

**2) Duplicate circular number** (expect 409):

```powershell
curl.exe -s -o NUL -w "HTTP %{http_code}`n" -X POST "$base/circulars/upload" `
  -H "Authorization: Bearer $tok" `
  -F "file=@backend\sample_circular.pdf" -F "circular_number=05/2024" -F "title=Dup"
# -> HTTP 409
```

**3) Non-PDF file** (expect 400):

```powershell
Set-Content "backend\notpdf.txt" "hello"
curl.exe -s -w " HTTP %{http_code}`n" -X POST "$base/circulars/upload" `
  -H "Authorization: Bearer $tok" `
  -F "file=@backend\notpdf.txt" -F "circular_number=06/2024" -F "title=Txt"
Remove-Item "backend\notpdf.txt"
# -> {"error":"Only PDF files are accepted."}  HTTP 400
```

**Confirm the circular is stored in MySQL:**

```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "USE circular_management; SELECT id, circular_number, title, file_size_kb, status FROM circulars;"
```

---

## Step 5 — WF-05 upload screen (frontend)

Rewrote `frontend/src/pages/AdminUpload.jsx` into a real upload form:
- Metadata fields (circular number, issue date, title, priority).
- Click or **drag-and-drop** PDF area, with client-side type/size checks (max 20 MB).
- Submits `multipart/form-data` to `/api/circulars/upload`.
- Shows a live **"Extracting text…"** spinner, then an **extraction result card**
  (metadata + page/word counts + extracted-text preview).

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

Logged in as **admin** → **Upload** screen renders with the metadata form and the
drag-and-drop PDF zone — no console errors.

> The browser file-picker cannot be automated by the preview tools, so the actual
> upload was validated against the same endpoint with `curl.exe` (Step 4). You can
> test the full UI manually using `backend\sample_circular.pdf`.

---

## Phase 2 outcome

| Step | Deliverable | Status |
|------|-------------|--------|
| 1 | PDF extraction service (`extract_text_with_meta`) | ✅ |
| 2 | Upload endpoint + 20 MB 413 handler (FR-06/08/09/10) | ✅ |
| 3 | Sample test PDF | ✅ |
| 4 | Backend tests: upload 201, duplicate 409, non-PDF 400 | ✅ |
| 5 | WF-05 upload screen (multipart, drag-drop, result card) | ✅ |
| 6 | Browser verification | ✅ |

**Result:** an administrator can upload a CBSL circular PDF; the system validates it,
extracts the text with PyMuPDF, stores the text + metadata in MySQL (`status = uploaded`),
and blocks duplicates. The stored text is the input for **Phase 3 — AI summarization**.

**Test fixture:** `backend/sample_circular.pdf`. **Demo admin:** `admin` / `password123`.
