"""Signed, time-limited tokens for password reset (FR-04).

Uses itsdangerous (a Flask dependency) so no extra table is needed — the token
itself carries the user id and is cryptographically signed with SECRET_KEY and
expires via max_age. This keeps the documented 11-table ERD unchanged.
"""
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from flask import current_app

_SALT = "password-reset"
RESET_MAX_AGE_SECONDS = 1800  # 30 minutes


def _serializer():
    return URLSafeTimedSerializer(current_app.config["SECRET_KEY"], salt=_SALT)


def generate_reset_token(user_id: int) -> str:
    return _serializer().dumps({"uid": user_id})


def verify_reset_token(token: str, max_age: int = RESET_MAX_AGE_SECONDS):
    """Return the user id if the token is valid and unexpired, else None."""
    try:
        data = _serializer().loads(token, max_age=max_age)
    except (BadSignature, SignatureExpired):
        return None
    return data.get("uid")
