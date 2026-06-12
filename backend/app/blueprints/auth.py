"""Authentication & role management (FR-01 to FR-05)."""
from datetime import datetime

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity

from ..extensions import db
from ..models.identity import User
from ..services.security import verify_password, hash_password
from ..services import audit, email
from ..services.tokens import generate_reset_token, verify_reset_token

auth_bp = Blueprint("auth", __name__)


def _is_strong(password: str) -> bool:
    """Minimum password policy: at least 8 characters."""
    return isinstance(password, str) and len(password) >= 8


@auth_bp.post("/login")
def login():
    """FR-01: secure username/password login, returns a JWT carrying the role."""
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")

    user = User.query.filter_by(username=username, is_active=True).first()
    if not user or not verify_password(password, user.password_hash):
        return jsonify({"error": "Invalid username or password"}), 401

    user.last_login = datetime.utcnow()
    db.session.commit()
    audit.record("USER_LOGIN", user_id=user.id, entity_type="User", entity_id=user.id)

    token = create_access_token(
        identity=str(user.id),
        additional_claims={"role": user.role, "username": user.username},
    )
    return jsonify({"access_token": token, "user": user.to_dict()})


@auth_bp.get("/me")
@jwt_required()
def me():
    """Return the current authenticated user's profile."""
    user = User.query.get(int(get_jwt_identity()))
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(user.to_dict())


@auth_bp.post("/forgot-password")
def forgot_password():
    """FR-04: request a password reset link via registered email.

    Always returns a generic success so the endpoint never reveals which emails
    exist. In development the reset URL is also returned/logged for convenience.
    """
    data = request.get_json(silent=True) or {}
    email_addr = (data.get("email") or "").strip().lower()

    generic = {"message": "If that email is registered, a reset link has been sent."}
    user = User.query.filter_by(email=email_addr, is_active=True).first()
    if not user:
        return jsonify(generic)

    token = generate_reset_token(user.id)
    reset_url = f"{current_app.config['FRONTEND_ORIGIN']}/reset-password?token={token}"
    email.send_email(
        to=user.email,
        subject="Circular Hub — Password Reset",
        body=(
            f"Hello {user.full_name},\n\n"
            f"Use the link below to reset your password (valid for 30 minutes):\n"
            f"{reset_url}\n\n"
            f"If you did not request this, you can ignore this email."
        ),
    )
    audit.record("PASSWORD_RESET_REQUESTED", user_id=user.id,
                 entity_type="User", entity_id=user.id)

    # Expose the link only in debug/development to make testing/demo easy.
    if current_app.debug:
        return jsonify({**generic, "dev_reset_url": reset_url})
    return jsonify(generic)


@auth_bp.post("/reset-password")
def reset_password():
    """FR-04: set a new password using a valid, unexpired reset token."""
    data = request.get_json(silent=True) or {}
    token = data.get("token", "")
    new_password = data.get("password", "")

    user_id = verify_reset_token(token)
    if not user_id:
        return jsonify({"error": "Invalid or expired reset link."}), 400
    if not _is_strong(new_password):
        return jsonify({"error": "Password must be at least 8 characters."}), 400

    user = User.query.get(user_id)
    if not user or not user.is_active:
        return jsonify({"error": "Account not found."}), 404

    user.password_hash = hash_password(new_password)
    db.session.commit()
    audit.record("PASSWORD_RESET", user_id=user.id, entity_type="User", entity_id=user.id)
    return jsonify({"message": "Password updated. You can now sign in."})


@auth_bp.post("/change-password")
@jwt_required()
def change_password():
    """Logged-in user changes their own password (current + new)."""
    data = request.get_json(silent=True) or {}
    current = data.get("current_password", "")
    new_password = data.get("new_password", "")

    user = User.query.get(int(get_jwt_identity()))
    if not user or not verify_password(current, user.password_hash):
        return jsonify({"error": "Current password is incorrect."}), 400
    if not _is_strong(new_password):
        return jsonify({"error": "New password must be at least 8 characters."}), 400

    user.password_hash = hash_password(new_password)
    db.session.commit()
    audit.record("PASSWORD_CHANGED", user_id=user.id, entity_type="User", entity_id=user.id)
    return jsonify({"message": "Password changed."})
