"""Employee-engagement tables: ACKNOWLEDGEMENTS, NOTIFICATIONS."""
from datetime import datetime
from ..extensions import db


class Acknowledgement(db.Model):
    """ACKNOWLEDGEMENTS — per-employee reading and acknowledgement records.

    Status drives the red/amber/green colour coding in WF-02/03/04:
      Unread  -> red    | Read -> amber | Acknowledged -> green
    """
    __tablename__ = "acknowledgements"

    STATUSES = ("Unread", "Read", "Acknowledged")

    id = db.Column(db.Integer, primary_key=True)
    circular_id = db.Column(db.Integer, db.ForeignKey("circulars.id"), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    status = db.Column(db.String(20), default="Unread", nullable=False)
    read_at = db.Column(db.DateTime)
    acknowledged_at = db.Column(db.DateTime)
    is_late = db.Column(db.Boolean, default=False)   # ack after deadline (FR-25)

    __table_args__ = (
        db.UniqueConstraint("circular_id", "user_id", name="uq_ack_user_circular"),
    )

    circular = db.relationship("Circular", back_populates="acknowledgements")
    user = db.relationship("User", back_populates="acknowledgements")

    def to_dict(self):
        return {
            "id": self.id,
            "circular_id": self.circular_id,
            "user_id": self.user_id,
            "status": self.status,
            "read_at": self.read_at.isoformat() if self.read_at else None,
            "acknowledged_at": self.acknowledged_at.isoformat()
            if self.acknowledged_at else None,
            "is_late": self.is_late,
        }


class Notification(db.Model):
    """NOTIFICATIONS — in-app notification records (FR-22)."""
    __tablename__ = "notifications"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    circular_id = db.Column(db.Integer, db.ForeignKey("circulars.id"))
    message = db.Column(db.String(512), nullable=False)
    # In-app destination for this notification (e.g. "/requests" or
    # "/circulars/5"). Drives click-through navigation in the notification bell.
    link = db.Column(db.String(255))
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "circular_id": self.circular_id,
            "message": self.message,
            "link": self.link,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
