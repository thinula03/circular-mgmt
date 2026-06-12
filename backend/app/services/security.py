"""Password hashing (NFR-06) and role-based access control (NFR-07)."""
from functools import wraps

import bcrypt
from flask import jsonify
from flask_jwt_extended import get_jwt, verify_jwt_in_request

WORK_FACTOR = 12  # NFR-06 minimum bcrypt work factor


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt(rounds=WORK_FACTOR)).decode()


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode(), hashed.encode())
    except (ValueError, TypeError):
        return False


def roles_required(*allowed_roles):
    """Decorator enforcing RBAC on a route (NFR-07)."""
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            role = get_jwt().get("role")
            if role not in allowed_roles:
                return jsonify({"error": "Forbidden: insufficient role"}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator
