"""Email delivery (FR-04, FR-23).

No SMTP server is configured for the prototype, so in development we 'send' email
by logging it and appending to a local outbox file. Swapping in real SMTP later is
a single function change.
"""
import os
from datetime import datetime

from flask import current_app


def send_email(to: str, subject: str, body: str) -> dict:
    """Deliver an email. In dev this logs + writes to backend/outbox.log."""
    record = (
        f"\n----- EMAIL {datetime.utcnow().isoformat()} -----\n"
        f"To: {to}\nSubject: {subject}\n\n{body}\n"
    )
    # Console log
    print(record, flush=True)
    # File outbox (handy for demos / verification)
    try:
        backend_root = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        )
        with open(os.path.join(backend_root, "outbox.log"), "a", encoding="utf-8") as fh:
            fh.write(record)
    except OSError:
        pass
    return {"to": to, "subject": subject, "delivered": True}
