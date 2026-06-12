"""In-app notifications (FR-22)."""
from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models.engagement import Notification

notifications_bp = Blueprint("notifications", __name__)


@notifications_bp.get("")
@jwt_required()
def list_notifications():
    uid = int(get_jwt_identity())
    items = (Notification.query
             .filter_by(user_id=uid)
             .order_by(Notification.created_at.desc())
             .limit(50).all())
    unread = Notification.query.filter_by(user_id=uid, is_read=False).count()
    return jsonify({"unread": unread, "items": [n.to_dict() for n in items]})


@notifications_bp.post("/<int:notif_id>/read")
@jwt_required()
def mark_read(notif_id):
    uid = int(get_jwt_identity())
    n = Notification.query.filter_by(id=notif_id, user_id=uid).first()
    if not n:
        return jsonify({"error": "Notification not found."}), 404
    n.is_read = True
    db.session.commit()
    return jsonify(n.to_dict())


@notifications_bp.post("/read-all")
@jwt_required()
def mark_all_read():
    uid = int(get_jwt_identity())
    Notification.query.filter_by(user_id=uid, is_read=False).update({"is_read": True})
    db.session.commit()
    return jsonify({"message": "All notifications marked read."})
