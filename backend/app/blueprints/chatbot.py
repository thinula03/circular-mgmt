"""RAG chatbot endpoint (FR-36 to FR-39)."""
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models.system import ChatLog
from ..models.circular import Circular
from ..ai import get_chatbot, get_index

chatbot_bp = Blueprint("chatbot", __name__)


@chatbot_bp.post("/ask")
@jwt_required()
def ask():
    """FR-36/37/38: answer a natural-language question, grounded with citations."""
    data = request.get_json(silent=True) or {}
    question = (data.get("question") or "").strip()
    if not question:
        return jsonify({"error": "Question is required"}), 400

    # Lazily build the index on first use (e.g. after a restart with no rebuild yet).
    index = get_index(current_app.config)
    if index.is_empty():
        index.build(Circular.query.filter_by(status="published").all())

    chatbot = get_chatbot(current_app.config)
    result = chatbot.answer(question, top_k=5)

    # FR-39: persist Q/A pair to CHAT_LOG
    log = ChatLog(
        user_id=int(get_jwt_identity()),
        question=question,
        answer=result["answer"],
        citations=result["citations"],
    )
    db.session.add(log)
    db.session.commit()
    return jsonify({
        "answer": result["answer"],
        "citations": result["citations"],
        "chat_id": log.id,
    })


@chatbot_bp.get("/history")
@jwt_required()
def history():
    """FR-39: return this user's chat history."""
    logs = (ChatLog.query
            .filter_by(user_id=int(get_jwt_identity()))
            .order_by(ChatLog.created_at.asc())
            .all())
    return jsonify([log.to_dict() for log in logs])
