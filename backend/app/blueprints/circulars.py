"""Circular upload, listing, search (FR-06 to FR-10, FR-27 to FR-30)."""
import os
import uuid
from datetime import datetime, timedelta

from flask import Blueprint, request, jsonify, current_app, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from werkzeug.utils import secure_filename
from sqlalchemy import or_

from ..extensions import db
from ..models.circular import Circular, Summary, Classification
from ..models.engagement import Acknowledgement
from ..services.security import roles_required
from ..services import audit, pdf_extract, distribution
from ..ai import get_engine, get_index

circulars_bp = Blueprint("circulars", __name__)

ALLOWED_EXTENSIONS = {".pdf"}


def _circular_list_item(circular, my_status):
    """Shape a circular for the list view (WF-02), with the viewer's ack status."""
    data = circular.to_dict()
    data["my_status"] = my_status                       # Unread/Read/Acknowledged/None
    data["categories"] = [c.category for c in circular.classifications]
    data["has_summary"] = circular.summary is not None
    return data


@circulars_bp.get("")
@jwt_required()
def list_circulars():
    """FR-28/29: search + filter circulars, scoped by role.

    Employees see only circulars routed to them (i.e. they have an acknowledgement
    record); Managers/Administrators see all. Supports keyword search across title,
    summary and category, plus category / ack-status / department / date filters.
    """
    uid = int(get_jwt_identity())
    role = get_jwt().get("role")
    args = request.args
    q = (args.get("q") or "").strip()

    # ---- base query + role scoping, paired with the viewer's ack ----
    ack_join = (Acknowledgement.circular_id == Circular.id) & (Acknowledgement.user_id == uid)
    if role == "Employee":
        query = (db.session.query(Circular, Acknowledgement)
                 .join(Acknowledgement, ack_join)
                 .filter(Circular.status == "published"))
    else:  # Manager / Administrator see everything, with their own ack if any
        query = db.session.query(Circular, Acknowledgement).outerjoin(Acknowledgement, ack_join)

    # ---- keyword search (FR-28): title, summary text, or category ----
    if q:
        like = f"%{q}%"
        query = query.filter(or_(
            Circular.title.ilike(like),
            Circular.circular_number.ilike(like),
            Circular.summary.has(Summary.summary_text.ilike(like)),
            Circular.classifications.any(Classification.category.ilike(like)),
        ))

    # ---- filters (FR-29) ----
    category = args.get("category")
    if category:
        query = query.filter(Circular.classifications.any(Classification.category == category))
    status = args.get("status")
    if status:
        query = query.filter(Acknowledgement.status == status)
    department_id = args.get("department_id")
    if department_id:
        query = query.filter(Circular.departments.any(department_id=int(department_id)))
    date_from = args.get("date_from")
    if date_from:
        query = query.filter(Circular.issue_date >= date_from)
    date_to = args.get("date_to")
    if date_to:
        query = query.filter(Circular.issue_date <= date_to)

    # MySQL/MariaDB sorts NULLs last on DESC, which is what we want (drafts last).
    rows = query.order_by(Circular.published_at.desc(),
                          Circular.created_at.desc()).all()
    return jsonify([
        _circular_list_item(circ, ack.status if ack else None) for circ, ack in rows
    ])


@circulars_bp.get("/<int:circular_id>")
@jwt_required()
def get_circular(circular_id):
    circular = Circular.query.get(circular_id)
    if not circular:
        return jsonify({"error": "Circular not found"}), 404

    uid = int(get_jwt_identity())
    ack = Acknowledgement.query.filter_by(circular_id=circular_id, user_id=uid).first()
    # SD-02: opening an unread circular marks it Read.
    if ack and ack.status == "Unread":
        ack.status = "Read"
        ack.read_at = datetime.utcnow()
        db.session.commit()

    data = circular.to_dict(include_text=True)
    data["my_status"] = ack.status if ack else None
    data["my_ack"] = ack.to_dict() if ack else None
    data["summary"] = circular.summary.to_dict() if circular.summary else None
    data["classifications"] = [c.to_dict() for c in circular.classifications]
    return jsonify(data)


@circulars_bp.get("/<int:circular_id>/download")
@jwt_required()
def download_circular(circular_id):
    """FR-30: download the original PDF of a circular."""
    circular = Circular.query.get(circular_id)
    if not circular or not circular.file_path or not os.path.exists(circular.file_path):
        return jsonify({"error": "Original PDF not available."}), 404
    audit.record("CIRCULAR_DOWNLOADED", user_id=int(get_jwt_identity()),
                 entity_type="Circular", entity_id=circular.id)
    download_name = f"Circular_{circular.circular_number.replace('/', '-')}.pdf"
    return send_file(circular.file_path, mimetype="application/pdf",
                     as_attachment=True, download_name=download_name)


@circulars_bp.post("/upload")
@jwt_required()
@roles_required("Administrator")
def upload_circular():
    """FR-06–FR-10: validate + store a CBSL circular PDF and extract its text.

    Pipeline: validate file (FR-09) -> duplicate check (FR-10) -> save PDF ->
    extract text via PyMuPDF (FR-07) -> capture metadata (FR-08) -> create record.
    AI summarization (Phase 3) runs separately on the stored circular.
    """
    # ---- file presence & type (FR-09) ----
    file = request.files.get("file")
    if not file or not file.filename:
        return jsonify({"error": "A PDF file is required."}), 400
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        return jsonify({"error": "Only PDF files are accepted."}), 400

    # ---- metadata from form (FR-08) ----
    circular_number = (request.form.get("circular_number") or "").strip()
    title = (request.form.get("title") or "").strip()
    priority = request.form.get("priority", "Medium")
    issue_date_raw = (request.form.get("issue_date") or "").strip()
    if not circular_number or not title:
        return jsonify({"error": "Circular number and title are required."}), 400
    if priority not in Circular.PRIORITIES:
        priority = "Medium"
    issue_date = None
    if issue_date_raw:
        try:
            issue_date = datetime.strptime(issue_date_raw, "%Y-%m-%d").date()
        except ValueError:
            return jsonify({"error": "issue_date must be YYYY-MM-DD."}), 400

    # ---- duplicate detection (FR-10) ----
    if Circular.query.filter_by(circular_number=circular_number).first():
        return jsonify({
            "error": f"A circular numbered '{circular_number}' already exists.",
            "duplicate": True,
        }), 409

    # ---- save the PDF ----
    safe_name = f"{uuid.uuid4().hex}_{secure_filename(file.filename)}"
    save_path = os.path.join(current_app.config["UPLOAD_FOLDER"], safe_name)
    file.save(save_path)
    size_kb = max(1, round(os.path.getsize(save_path) / 1024))

    # ---- extract text via PyMuPDF (FR-07) ----
    try:
        text, page_count = pdf_extract.extract_text_with_meta(save_path)
    except ValueError as exc:
        os.remove(save_path)  # not a valid PDF — clean up
        return jsonify({"error": str(exc)}), 400

    # ---- persist (FR-27 storage) ----
    circular = Circular(
        circular_number=circular_number,
        title=title,
        issue_date=issue_date,
        file_path=save_path,
        file_size_kb=size_kb,
        extracted_text=text,
        priority=priority,
        status="uploaded",
        uploaded_by=int(get_jwt_identity()),
    )
    db.session.add(circular)
    db.session.commit()
    audit.record("CIRCULAR_UPLOADED", user_id=int(get_jwt_identity()),
                 entity_type="Circular", entity_id=circular.id,
                 detail=f"{circular_number} ({size_kb} KB, {page_count} pages)")

    return jsonify({
        "circular": circular.to_dict(),
        "extraction": {
            "page_count": page_count,
            "char_count": len(text),
            "word_count": len(text.split()),
            "preview": text[:600],
        },
        "message": "Uploaded and text extracted. Ready for AI summarization.",
    }), 201


@circulars_bp.post("/<int:circular_id>/summarize")
@jwt_required()
@roles_required("Administrator")
def summarize_circular(circular_id):
    """FR-11–FR-16: run the spaCy->BERT->BART pipeline on a stored circular.

    Generates the abstractive summary + NER entities, auto-classifies the
    compliance category (FR-18), and publishes the circular.
    """
    circular = Circular.query.get(circular_id)
    if not circular:
        return jsonify({"error": "Circular not found."}), 404
    if not (circular.extracted_text or "").strip():
        return jsonify({"error": "Circular has no extracted text to summarize."}), 400

    target_words = int(request.args.get("target_words", 200))
    target_words = max(80, min(target_words, 300))  # FR-14 configurable, bounded

    # FR-25: acknowledgement deadline (days from now, default 7).
    ack_days = int(request.args.get("ack_days", 7))
    circular.ack_deadline = datetime.utcnow() + timedelta(days=max(1, ack_days))

    circular.status = "processing"  # FR-17 status the UI can show
    db.session.commit()

    engine = get_engine(current_app.config)
    try:
        result = engine.summarize(circular.extracted_text, target_words=target_words)
    except Exception as exc:  # noqa: BLE001 — surface failure, mark circular failed
        circular.status = "failed"
        db.session.commit()
        return jsonify({"error": f"Summarization failed: {exc}"}), 500

    # Replace any previous summary so re-running is idempotent.
    if circular.summary:
        db.session.delete(circular.summary)
        db.session.flush()
    summary = Summary(
        circular_id=circular.id,
        summary_text=result.summary_text,
        entities=result.entities,
        word_count=result.word_count,
        bert_model=result.bert_model,
        bart_model=result.bart_model,
        processing_seconds=result.processing_seconds,
    )
    db.session.add(summary)

    # Auto-classification (FR-18) — refresh on each run.
    Classification.query.filter_by(circular_id=circular.id, is_manual=False).delete()
    for c in engine.classify(circular.extracted_text):
        db.session.add(Classification(circular_id=circular.id, **c))

    circular.status = "published"
    circular.published_at = datetime.utcnow()
    db.session.commit()
    audit.record("CIRCULAR_SUMMARIZED", user_id=int(get_jwt_identity()),
                 entity_type="Circular", entity_id=circular.id,
                 detail=f"{result.bart_model} in {result.processing_seconds}s")

    # FR-19/22/23: route to departments + notify recipients on publish.
    dist = distribution.route_and_notify(circular)

    # FR-40: rebuild the FAISS vector index so the new circular is searchable.
    try:
        get_index(current_app.config).build(
            Circular.query.filter_by(status="published").all()
        )
    except Exception:  # noqa: BLE001 — indexing failure shouldn't fail publishing
        pass

    return jsonify({
        "circular": circular.to_dict(),
        "summary": summary.to_dict(),
        "classifications": [c.to_dict() for c in circular.classifications],
        "distribution": dist,
    })


@circulars_bp.patch("/<int:circular_id>/classification")
@jwt_required()
@roles_required("Manager", "Administrator")
def override_classification(circular_id):
    """FR-20: compliance officer overrides the auto-classification and re-routes."""
    circular = Circular.query.get(circular_id)
    if not circular:
        return jsonify({"error": "Circular not found."}), 404
    data = request.get_json(silent=True) or {}
    categories = data.get("categories") or []
    valid = [c for c in categories if c in Classification.CATEGORIES]
    if not valid:
        return jsonify({"error": f"Provide categories from {Classification.CATEGORIES}."}), 400

    Classification.query.filter_by(circular_id=circular.id).delete()
    for cat in valid:
        db.session.add(Classification(circular_id=circular.id, category=cat,
                                      confidence=None, is_manual=True))
    db.session.commit()
    audit.record("CLASSIFICATION_OVERRIDDEN", user_id=int(get_jwt_identity()),
                 entity_type="Circular", entity_id=circular.id,
                 detail=", ".join(valid))

    # Re-route if the circular is already published.
    dist = None
    if circular.status == "published":
        dist = distribution.route_and_notify(circular)
    return jsonify({
        "classifications": [c.to_dict() for c in circular.classifications],
        "distribution": dist,
    })


@circulars_bp.post("/reminders/run")
@jwt_required()
@roles_required("Manager", "Administrator")
def run_reminders():
    """FR-26: send reminders for un-acknowledged circulars near/after deadline."""
    result = distribution.run_reminders()
    return jsonify(result)
