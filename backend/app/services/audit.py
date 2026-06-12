"""Write-once audit logging (AUDIT_LOG immutability, thesis §4.3)."""
from ..extensions import db
from ..models.system import AuditLog


def record(action: str, user_id=None, entity_type=None, entity_id=None, detail=None):
    """Insert an immutable audit entry. There is no update/delete counterpart."""
    entry = AuditLog(
        user_id=user_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        detail=detail,
    )
    db.session.add(entry)
    db.session.commit()
    return entry
