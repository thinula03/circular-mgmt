"""Admin user management (FR-02 roles, FR-05 department assignment).

All routes are Administrator-only (RBAC, NFR-07). Deactivation is a soft delete
(is_active=False) to preserve referential integrity in historical records.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models.identity import User, Department
from ..services.security import roles_required, hash_password
from ..services import audit

users_bp = Blueprint("users", __name__)


@users_bp.get("/departments")
@jwt_required()
def list_departments():
    """Departments list — used to populate the assignment dropdown."""
    return jsonify([d.to_dict() for d in Department.query.order_by(Department.name).all()])


@users_bp.get("")
@jwt_required()
@roles_required("Administrator")
def list_users():
    users = User.query.order_by(User.created_at.desc()).all()
    return jsonify([u.to_dict() for u in users])


@users_bp.post("")
@jwt_required()
@roles_required("Administrator")
def create_user():
    """Create a user and assign role + department (FR-02, FR-05)."""
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    email_addr = (data.get("email") or "").strip().lower()
    full_name = (data.get("full_name") or "").strip()
    role = data.get("role", "Employee")
    department_id = data.get("department_id")
    password = data.get("password") or ""

    # Validation
    if not username or not email_addr or not full_name:
        return jsonify({"error": "username, email and full_name are required."}), 400
    if role not in User.ROLES:
        return jsonify({"error": f"role must be one of {User.ROLES}."}), 400
    if len(password) < 8:
        return jsonify({"error": "password must be at least 8 characters."}), 400
    if User.query.filter_by(username=username).first():
        return jsonify({"error": "Username already exists."}), 409
    if User.query.filter_by(email=email_addr).first():
        return jsonify({"error": "Email already exists."}), 409
    if department_id and not Department.query.get(department_id):
        return jsonify({"error": "Department not found."}), 400

    user = User(
        username=username,
        email=email_addr,
        full_name=full_name,
        role=role,
        department_id=department_id or None,
        password_hash=hash_password(password),
    )
    db.session.add(user)
    db.session.commit()
    audit.record("USER_CREATED", user_id=int(get_jwt_identity()),
                 entity_type="User", entity_id=user.id, detail=f"{username} ({role})")
    return jsonify(user.to_dict()), 201


@users_bp.patch("/<int:user_id>")
@jwt_required()
@roles_required("Administrator")
def update_user(user_id):
    """Update role, department, or full name (FR-02, FR-05)."""
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found."}), 404
    data = request.get_json(silent=True) or {}

    if "role" in data:
        if data["role"] not in User.ROLES:
            return jsonify({"error": f"role must be one of {User.ROLES}."}), 400
        user.role = data["role"]
    if "department_id" in data:
        dep_id = data["department_id"]
        if dep_id and not Department.query.get(dep_id):
            return jsonify({"error": "Department not found."}), 400
        user.department_id = dep_id or None
    if "full_name" in data and data["full_name"].strip():
        user.full_name = data["full_name"].strip()

    db.session.commit()
    audit.record("USER_UPDATED", user_id=int(get_jwt_identity()),
                 entity_type="User", entity_id=user.id)
    return jsonify(user.to_dict())


@users_bp.post("/<int:user_id>/deactivate")
@jwt_required()
@roles_required("Administrator")
def deactivate_user(user_id):
    """Soft delete (FR — preserves history). Admins cannot deactivate themselves."""
    if user_id == int(get_jwt_identity()):
        return jsonify({"error": "You cannot deactivate your own account."}), 400
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found."}), 404
    user.is_active = False
    db.session.commit()
    audit.record("USER_DEACTIVATED", user_id=int(get_jwt_identity()),
                 entity_type="User", entity_id=user.id)
    return jsonify(user.to_dict())


@users_bp.post("/<int:user_id>/activate")
@jwt_required()
@roles_required("Administrator")
def activate_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found."}), 404
    user.is_active = True
    db.session.commit()
    audit.record("USER_ACTIVATED", user_id=int(get_jwt_identity()),
                 entity_type="User", entity_id=user.id)
    return jsonify(user.to_dict())
