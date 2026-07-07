"""PDF text extraction via PyMuPDF, with a Tesseract OCR fallback (FR-07).

Digital PDFs are read directly from their text layer. Scanned circulars (image
pages, or pages whose embedded text layer is garbled low-quality OCR) are
re-OCR'd with Tesseract for clean text — otherwise the RAG chatbot and
summariser are fed corrupted input (e.g. "positions" -> "p.o.)itiottt").

OCR is optional: if pytesseract or the Tesseract engine isn't installed, we log
a warning and fall back to the embedded text layer. Set the engine path with the
TESSERACT_CMD env var if Tesseract isn't on PATH (typical on Windows, e.g.
C:\\Program Files\\Tesseract-OCR\\tesseract.exe).
"""
import os
import re
import math
import logging
from collections import Counter

log = logging.getLogger(__name__)

_OCR_DPI = 300              # render resolution for OCR
_MIN_TEXT_CHARS = 100       # below this, a page is treated as needing OCR
_ocr_warned = False         # warn about a missing OCR engine only once per run


def extract_text(file_path: str) -> str:
    """Extract full text from a PDF. Returns '' if PyMuPDF is unavailable."""
    text, _ = extract_text_with_meta(file_path)
    return text


def extract_text_with_meta(file_path: str):
    """Return (full_text, page_count) extracted from a PDF.

    Each page uses its text layer unless the page is scanned or its text looks
    garbled, in which case Tesseract OCR is attempted. Raises ValueError if the
    file cannot be opened as a valid PDF.
    """
    import fitz  # PyMuPDF

    try:
        doc = fitz.open(file_path)
    except Exception as exc:  # corrupt / not a real PDF
        raise ValueError(f"Could not read PDF: {exc}") from exc

    page_texts = []
    with doc:
        page_count = doc.page_count
        for page in doc:
            layer = page.get_text() or ""
            if _needs_ocr(page, layer):
                ocr = _ocr_page(page)
                # Prefer OCR only when it produced meaningfully more/cleaner text.
                if ocr and len(ocr.strip()) >= max(_MIN_TEXT_CHARS, len(layer.strip()) * 0.6):
                    page_texts.append(ocr)
                    continue
            page_texts.append(layer)
    return _strip_repeating(page_texts, page_count), page_count


def _norm_line(line: str) -> str:
    """Normalise a line for repeat-detection: lowercase, drop a trailing page
    number, collapse whitespace."""
    s = re.sub(r"\s+", " ", (line or "").strip().lower())
    s = re.sub(r"\s*\d{1,4}$", "", s).strip()   # trailing page number varies per page
    return s


def _is_junk_marker(s: str) -> bool:
    """A parenthesised token that is not a valid list label — e.g. '(bo)' from a
    mangled table cell. Real markers '(a)', '(1)', '(iv)' are kept."""
    m = re.fullmatch(r"\(([a-z]{2,})\)", s.strip(), re.IGNORECASE)
    if not m:
        return False
    return not re.fullmatch(r"[ivxlcdm]+", m.group(1), re.IGNORECASE)  # keep roman


def _clean_line(line: str, boiler: set):
    """Return a cleaned line, or None to drop it (header/footer, stray table
    artifact, bare number, junk marker)."""
    stripped = line.strip()
    if not stripped:
        return None
    if _norm_line(line) in boiler:                       # repeated header/footer
        return None
    if re.fullmatch(r"[\d.\s()|-]{1,6}", stripped):      # bare page/section number, lone '|'
        return None
    if _is_junk_marker(stripped):                        # e.g. "(bo)"
        return None
    cleaned = re.sub(r"\s*\|\s*", " ", line).strip()     # drop table-cell pipes
    return cleaned or None


def _strip_repeating(page_texts, page_count):
    """Remove page headers/footers (lines recurring across pages) plus stray table
    artifacts (lone pipes, bare numbers, mangled markers), so they don't pollute
    summaries and search."""
    per_page = [[ln.rstrip() for ln in (t or "").split("\n")] for t in page_texts]

    boiler = set()
    if page_count >= 2:
        counts = Counter()
        for lines in per_page:
            for norm in {_norm_line(ln) for ln in lines if _norm_line(ln)}:
                counts[norm] += 1
        threshold = max(2, math.ceil(0.4 * page_count))
        boiler = {n for n, c in counts.items() if c >= threshold}

    out = []
    for lines in per_page:
        for ln in lines:
            cleaned = _clean_line(ln, boiler)
            if cleaned:
                out.append(cleaned)
    return "\n".join(out)


def _needs_ocr(page, layer: str) -> bool:
    """A page needs OCR if it's a scan (its text layer, if any, is unknown-quality
    embedded OCR), has almost no text, or its text layer looks garbled."""
    if _is_scanned(page):
        return True
    if len(layer.strip()) < _MIN_TEXT_CHARS:
        return True
    if _looks_garbled(layer):
        return True
    return False


def _is_scanned(page) -> bool:
    """True when a single image covers most of the page (a scanned page)."""
    try:
        images = page.get_images(full=True)
    except Exception:  # noqa: BLE001
        return False
    if not images:
        return False
    page_area = abs(page.rect.width * page.rect.height) or 1.0
    for img in images:
        try:
            for r in page.get_image_rects(img[0]):
                if abs(r.width * r.height) >= 0.5 * page_area:
                    return True
        except Exception:  # noqa: BLE001
            continue
    return False


def _looks_garbled(text: str) -> bool:
    """Heuristic: a high share of 'words' with no vowels or stray mid-word
    punctuation indicates a broken/low-quality OCR text layer."""
    words = re.findall(r"[A-Za-z][A-Za-z.)\-]{2,}", text)
    if len(words) < 20:
        return False
    bad = 0
    for w in words:
        core = re.sub(r"[.)\-]", "", w)
        if core and not re.search(r"[aeiouAEIOU]", core):       # no vowel
            bad += 1
        elif re.search(r"[a-z][.)][a-z]", w):                   # punctuation mid-word
            bad += 1
    return (bad / len(words)) > 0.25


def _ocr_page(page) -> str:
    """OCR a single page with Tesseract. Returns '' if OCR isn't available."""
    global _ocr_warned
    try:
        import pytesseract
        from PIL import Image
    except Exception:  # noqa: BLE001 — pytesseract/Pillow not installed
        if not _ocr_warned:
            log.warning("OCR skipped: install `pytesseract` and the Tesseract engine "
                        "to extract scanned PDFs.")
            _ocr_warned = True
        return ""

    cmd = os.environ.get("TESSERACT_CMD")
    if cmd:
        pytesseract.pytesseract.tesseract_cmd = cmd
    try:
        pix = page.get_pixmap(dpi=_OCR_DPI)
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        return pytesseract.image_to_string(img)
    except Exception as exc:  # noqa: BLE001 — engine missing / render failure
        log.warning("OCR failed (%s). Is the Tesseract engine installed and on "
                    "PATH or TESSERACT_CMD?", exc)
        return ""
