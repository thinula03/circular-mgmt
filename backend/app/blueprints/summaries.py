"""Summary view + acknowledgement (FR-13 to FR-15, FR-24)."""
from datetime import datetime

from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models.circular import Circular
from ..models.engagement import Acknowledgement
from ..services import audit

summaries_bp = Blueprint("summaries", __name__)


@summaries_bp.get("/<int:circular_id>")
@jwt_required()
def get_summary(circular_id):
    """Return the AI summary + NER entities for a circular (WF-03 left panel)."""
    circular = Circular.query.get(circular_id)
    if not circular or not circular.summary:
        return jsonify({"error": "Summary not available"}), 404
    return jsonify(circular.summary.to_dict())


@summaries_bp.post("/<int:circular_id>/acknowledge")
@jwt_required()
def acknowledge(circular_id):
    """FR-24: employee formally acknowledges reading a circular."""
    user_id = int(get_jwt_identity())
    ack = Acknowledgement.query.filter_by(
        circular_id=circular_id, user_id=user_id
    ).first()
    if not ack:
        ack = Acknowledgement(circular_id=circular_id, user_id=user_id)
        db.session.add(ack)

    circular = Circular.query.get(circular_id)
    now = datetime.utcnow()
    ack.status = "Acknowledged"
    ack.acknowledged_at = now
    if ack.read_at is None:
        ack.read_at = now
    if circular and circular.ack_deadline and now > circular.ack_deadline:
        ack.is_late = True  # FR-25 overdue flag
    db.session.commit()
    audit.record("CIRCULAR_ACKNOWLEDGED", user_id=user_id,
                 entity_type="Circular", entity_id=circular_id)
    return jsonify(ack.to_dict())
