"""Audit-log viewer for administrators (accountability / non-repudiation)."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required

from ..extensions import db
from ..models.system import AuditLog
from ..models.identity import User
from ..services.security import roles_required

audit_bp = Blueprint("audit", __name__)


@audit_bp.get("")
@jwt_required()
@roles_required("Administrator")
def list_audit():
    """List audit entries (newest first), filterable by action / user / date."""
    args = request.args
    actor = db.aliased(User)
    q = (db.session.query(AuditLog, actor)
         .outerjoin(actor, actor.id == AuditLog.user_id))

    if args.get("action"):
        q = q.filter(AuditLog.action == args["action"])
    if args.get("user_id"):
        q = q.filter(AuditLog.user_id == int(args["user_id"]))
    if args.get("date_from"):
        q = q.filter(AuditLog.created_at >= args["date_from"])
    if args.get("date_to"):
        q = q.filter(AuditLog.created_at <= args["date_to"])

    rows = q.order_by(AuditLog.created_at.desc()).limit(300).all()
    return jsonify([
        {**log.to_dict(),
         "actor": act.full_name if act else None,
         "username": act.username if act else None}
        for log, act in rows
    ])


@audit_bp.get("/actions")
@jwt_required()
@roles_required("Administrator")
def list_actions():
    """Distinct action names, to populate the filter dropdown."""
    rows = db.session.query(AuditLog.action).distinct().all()
    return jsonify(sorted(r[0] for r in rows))
