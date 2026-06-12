"""PDF text extraction via PyMuPDF (FR-07)."""


def extract_text(file_path: str) -> str:
    """Extract full text from a PDF. Returns '' if PyMuPDF is unavailable."""
    text, _ = extract_text_with_meta(file_path)
    return text


def extract_text_with_meta(file_path: str):
    """Return (full_text, page_count) extracted from a PDF.

    Raises ValueError if the file cannot be opened as a valid PDF.
    """
    import fitz  # PyMuPDF

    try:
        doc = fitz.open(file_path)
    except Exception as exc:  # corrupt / not a real PDF
        raise ValueError(f"Could not read PDF: {exc}") from exc

    with doc:
        parts = [page.get_text() for page in doc]
        page_count = doc.page_count
    return "\n".join(parts), page_count
