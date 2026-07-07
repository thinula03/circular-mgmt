"""System tables: AUDIT_LOG (write-once), CHAT_LOG, VECTOR_INDEX_METADATA."""
from datetime import datetime
from ..extensions import db


class AuditLog(db.Model):
    """AUDIT_LOG — immutable action trail.

    Write-once: the service layer only ever INSERTs. There is intentionally no
    update/delete path, enforcing immutability at the application level (thesis §4.3).
    """
    __tablename__ = "audit_log"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"))
    action = db.Column(db.String(120), nullable=False)   # e.g. CIRCULAR_PUBLISHED
    entity_type = db.Column(db.String(80))               # e.g. Circular
    entity_id = db.Column(db.Integer)
    detail = db.Column(db.String(512))
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "action": self.action,
            "entity_type": self.entity_type,
            "entity_id": self.entity_id,
            "detail": self.detail,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class ChatConversation(db.Model):
    """CHAT_CONVERSATIONS — a ChatGPT-style conversation grouping chat messages.

    Scope is set by circular_id: NULL = a global conversation (ask about any
    circular); a value = a conversation scoped to that single circular. Global and
    per-circular conversations are listed separately in the UI.
    """
    __tablename__ = "chat_conversations"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    circular_id = db.Column(db.Integer, db.ForeignKey("circulars.id"))  # NULL = global
    title = db.Column(db.String(200), nullable=False, default="New chat")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    messages = db.relationship("ChatLog", backref="conversation",
                               order_by="ChatLog.created_at",
                               cascade="all, delete-orphan")

    def to_dict(self, with_messages=False):
        data = {
            "id": self.id,
            "user_id": self.user_id,
            "circular_id": self.circular_id,
            "title": self.title,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "message_count": len(self.messages),
        }
        if with_messages:
            data["messages"] = [m.to_dict() for m in self.messages]
        return data


class ChatLog(db.Model):
    """CHAT_LOG — RAG chatbot question/answer pairs with citations (FR-39)."""
    __tablename__ = "chat_log"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    conversation_id = db.Column(db.Integer,
                                db.ForeignKey("chat_conversations.id"))
    question = db.Column(db.Text, nullable=False)
    answer = db.Column(db.Text, nullable=False)
    citations = db.Column(db.JSON)        # list of {circular_number, section}
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "conversation_id": self.conversation_id,
            "question": self.question,
            "answer": self.answer,
            "citations": self.citations or [],
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class ChangeRequest(db.Model):
    """CHANGE_REQUESTS — managers flag a problem on a circular; admins resolve it.

    status: Open (default) -> Solved / Not Solved (set by an administrator with a reply).
    """
    __tablename__ = "change_requests"

    STATUSES = ("Open", "Solved", "Not Solved")

    id = db.Column(db.Integer, primary_key=True)
    circular_id = db.Column(db.Integer, db.ForeignKey("circulars.id"), nullable=False)
    requester_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    message = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(20), nullable=False, default="Open")
    admin_reply = db.Column(db.Text)
    resolved_by = db.Column(db.Integer, db.ForeignKey("users.id"))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    resolved_at = db.Column(db.DateTime)


class VectorIndexMetadata(db.Model):
    """VECTOR_INDEX_METADATA — FAISS index state and rebuild history (FR-40)."""
    __tablename__ = "vector_index_metadata"

    id = db.Column(db.Integer, primary_key=True)
    total_vectors = db.Column(db.Integer, default=0)
    total_circulars = db.Column(db.Integer, default=0)
    embedding_model = db.Column(db.String(120))
    dimension = db.Column(db.Integer)
    index_path = db.Column(db.String(512))
    last_rebuilt_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "total_vectors": self.total_vectors,
            "total_circulars": self.total_circulars,
            "embedding_model": self.embedding_model,
            "dimension": self.dimension,
            "last_rebuilt_at": self.last_rebuilt_at.isoformat()
            if self.last_rebuilt_at else None,
        }
