"""RAG chatbot endpoint (FR-36 to FR-39).

Supports two scopes and ChatGPT-style conversations:
  * global chat  — ask about any published circular (circular_id omitted)
  * scoped chat  — ask about one circular only (circular_id set)
Messages are grouped into conversations; global and per-circular conversations
are listed separately.
"""
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models.system import ChatLog, ChatConversation
from ..models.circular import Circular
from ..ai import get_chatbot, get_index

chatbot_bp = Blueprint("chatbot", __name__)


def _title_from(question):
    q = " ".join((question or "").split())
    return (q[:60] + "…") if len(q) > 60 else (q or "New chat")


def _owned_conversation(conv_id):
    """Fetch a conversation owned by the current user, or None."""
    if not conv_id:
        return None
    return ChatConversation.query.filter_by(
        id=conv_id, user_id=int(get_jwt_identity())).first()


@chatbot_bp.post("/ask")
@jwt_required()
def ask():
    """FR-36/37/38: answer a question, grounded with citations, within a conversation."""
    data = request.get_json(silent=True) or {}
    question = (data.get("question") or "").strip()
    if not question:
        return jsonify({"error": "Question is required"}), 400

    uid = int(get_jwt_identity())
    circular_id = data.get("circular_id")          # None => global chat
    conversation_id = data.get("conversation_id")

    # Resolve (or create) the conversation this message belongs to.
    conv = _owned_conversation(conversation_id)
    if conv is None:
        conv = ChatConversation(user_id=uid, circular_id=circular_id,
                                title=_title_from(question))
        db.session.add(conv)
        db.session.flush()          # assign conv.id
    else:
        circular_id = conv.circular_id  # keep the conversation's own scope

    # Lazily build the index on first use (e.g. after a restart with no rebuild).
    index = get_index(current_app.config)
    if index.is_empty():
        index.build(Circular.query.filter_by(status="published").all())

    chatbot = get_chatbot(current_app.config)
    result = chatbot.answer(question, top_k=5, circular_id=circular_id)

    # FR-39: persist the Q/A pair to the conversation.
    log = ChatLog(user_id=uid, conversation_id=conv.id, question=question,
                  answer=result["answer"], citations=result["citations"])
    db.session.add(log)
    db.session.commit()
    return jsonify({
        "answer": result["answer"],
        "citations": result["citations"],
        "chat_id": log.id,
        "conversation_id": conv.id,
        "conversation_title": conv.title,
    })


@chatbot_bp.get("/conversations")
@jwt_required()
def list_conversations():
    """List the user's conversations for a scope (global unless circular_id given)."""
    uid = int(get_jwt_identity())
    circular_id = request.args.get("circular_id", type=int)
    query = ChatConversation.query.filter_by(user_id=uid)
    if circular_id is not None:
        query = query.filter_by(circular_id=circular_id)
    else:
        query = query.filter(ChatConversation.circular_id.is_(None))
    convs = query.order_by(ChatConversation.updated_at.desc()).all()
    return jsonify([c.to_dict() for c in convs])


@chatbot_bp.post("/conversations")
@jwt_required()
def create_conversation():
    """Create a new empty conversation (optionally scoped to a circular)."""
    data = request.get_json(silent=True) or {}
    conv = ChatConversation(user_id=int(get_jwt_identity()),
                            circular_id=data.get("circular_id"),
                            title="New chat")
    db.session.add(conv)
    db.session.commit()
    return jsonify(conv.to_dict()), 201


@chatbot_bp.get("/conversations/<int:conv_id>")
@jwt_required()
def get_conversation(conv_id):
    """Return a conversation with all its messages (FR-39)."""
    conv = _owned_conversation(conv_id)
    if conv is None:
        return jsonify({"error": "Conversation not found."}), 404
    return jsonify(conv.to_dict(with_messages=True))


@chatbot_bp.delete("/conversations/<int:conv_id>")
@jwt_required()
def delete_conversation(conv_id):
    """Delete a conversation and its messages."""
    conv = _owned_conversation(conv_id)
    if conv is None:
        return jsonify({"error": "Conversation not found."}), 404
    db.session.delete(conv)
    db.session.commit()
    return jsonify({"message": "Conversation deleted."})
