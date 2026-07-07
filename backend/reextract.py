"""Re-run PDF text extraction (with OCR) on already-stored circulars.

Useful after enabling the OCR fallback: circulars uploaded earlier still hold the
old (possibly garbled) text in the database. This re-extracts from the stored PDF,
updates extracted_text, and rebuilds the RAG vector index.

Usage:
  python reextract.py            # re-extract ALL circulars
  python reextract.py 5          # re-extract only circular id 5
"""
import os
import sys

from app import create_app
from app.extensions import db
from app.models.circular import Circular
from app.services import pdf_extract
from app.ai import get_index


def main():
    only_id = int(sys.argv[1]) if len(sys.argv) > 1 else None
    app = create_app()
    with app.app_context():
        q = Circular.query
        if only_id:
            q = q.filter_by(id=only_id)
        circulars = q.all()
        if not circulars:
            print("No circulars found.")
            return

        for c in circulars:
            if not c.file_path or not os.path.exists(c.file_path):
                print(f"[skip] #{c.id} {c.circular_number}: PDF not found on disk.")
                continue
            before = len(c.extracted_text or "")
            try:
                text, pages = pdf_extract.extract_text_with_meta(c.file_path)
            except ValueError as exc:
                print(f"[fail] #{c.id} {c.circular_number}: {exc}")
                continue
            c.extracted_text = text
            db.session.commit()
            print(f"[ok]   #{c.id} {c.circular_number}: {before} -> {len(text)} chars "
                  f"({pages} pages)")

        # Rebuild the vector index from the refreshed text.
        stats = get_index(app.config).build(
            Circular.query.filter_by(status="published").all())
        print(f"\nRebuilt vector index: {stats}")


if __name__ == "__main__":
    main()
