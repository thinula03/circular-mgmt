"""ORM models — the 11 ERD tables (thesis Figure 4.2).

Importing this package registers every model with SQLAlchemy so that
`db.create_all()` and Alembic-style migrations see the full schema.
"""
from .identity import User, Department, CircularDepartment
from .circular import Circular, Summary, Classification
from .engagement import Acknowledgement, Notification
from .system import (AuditLog, ChatLog, ChatConversation, VectorIndexMetadata,
                     ChangeRequest)

__all__ = [
    "User",
    "Department",
    "CircularDepartment",
    "Circular",
    "Summary",
    "Classification",
    "Acknowledgement",
    "Notification",
    "AuditLog",
    "ChatLog",
    "ChatConversation",
    "VectorIndexMetadata",
    "ChangeRequest",
]
