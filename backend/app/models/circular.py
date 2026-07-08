"""Circular content tables: CIRCULARS, SUMMARIES, CLASSIFICATIONS."""
from datetime import datetime
from ..extensions import db


class Circular(db.Model):
    """CIRCULARS — PDF metadata, extracted text, lifecycle status."""
    __tablename__ = "circulars"

    STATUSES = ("uploaded", "processing", "review", "published", "failed")
    PRIORITIES = ("High", "Medium", "Low")

    id = db.Column(db.Integer, primary_key=True)
    circular_number = db.Column(db.String(80), nullable=False, index=True)  # FR-08
    title = db.Column(db.String(255), nullable=False)
    issue_date = db.Column(db.Date)
    file_path = db.Column(db.String(512))          # stored original PDF (FR-30)
    file_size_kb = db.Column(db.Integer)
    extracted_text = db.Column(db.Text)            # PyMuPDF output (FR-07)
    priority = db.Column(db.String(10), default="Medium")  # FR-21
    status = db.Column(db.String(20), default="uploaded")
    ack_deadline = db.Column(db.DateTime)          # FR-25
    uploaded_by = db.Column(db.Integer, db.ForeignKey("users.id"))
    # The earlier circular this one amends (self-reference). NULL for most.
    amends_circular_id = db.Column(db.Integer, db.ForeignKey("circulars.id"))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    published_at = db.Column(db.DateTime)

    summary = db.relationship("Summary", back_populates="circular", uselist=False)
    classifications = db.relationship("Classification", back_populates="circular")
    departments = db.relationship("CircularDepartment", backref="circular_link")
    acknowledgements = db.relationship("Acknowledgement", back_populates="circular")
    # `amends` = the circular this one amends; `amended_by` = circulars amending this one.
    amends = db.relationship("Circular", remote_side=[id],
                             foreign_keys=[amends_circular_id],
                             backref="amended_by")

    # ---- amendment / supersede helpers (derived, nothing stored) --------
    @property
    def superseding(self):
        """Published circulars that amend this one (newest first)."""
        pub = [c for c in self.amended_by if c.status == "published"]
        return sorted(pub, key=lambda c: (c.published_at or c.created_at or datetime.min),
                      reverse=True)

    @property
    def is_superseded(self):
        return len(self.superseding) > 0

    @property
    def latest_amender(self):
        s = self.superseding
        return s[0] if s else None

    def to_dict(self, include_text=False):
        data = {
            "id": self.id,
            "circular_number": self.circular_number,
            "title": self.title,
            "issue_date": self.issue_date.isoformat() if self.issue_date else None,
            "file_size_kb": self.file_size_kb,
            "priority": self.priority,
            "status": self.status,
            "ack_deadline": self.ack_deadline.isoformat() if self.ack_deadline else None,
            "published_at": self.published_at.isoformat() if self.published_at else None,
            "amends_circular_id": self.amends_circular_id,
            "amends": self._ref(self.amends),
            "amended_by": self._ref(self.latest_amender),
            "is_superseded": self.is_superseded,
        }
        if include_text:
            data["extracted_text"] = self.extracted_text
        return data

    @staticmethod
    def _ref(c):
        """Compact reference to a related circular (or None)."""
        if not c:
            return None
        return {"id": c.id, "circular_number": c.circular_number, "title": c.title}


class Summary(db.Model):
    """SUMMARIES — AI-generated output, named entities (JSON), model versions.

    `entities` is a JSON column: the NER set is always read as a whole, so
    over-normalising it into a separate table adds no value (thesis §4.3).
    """
    __tablename__ = "summaries"

    id = db.Column(db.Integer, primary_key=True)
    circular_id = db.Column(db.Integer, db.ForeignKey("circulars.id"), nullable=False)
    summary_text = db.Column(db.Text, nullable=False)        # BART output (FR-13)
    entities = db.Column(db.JSON)                            # spaCy NER (FR-15)
    word_count = db.Column(db.Integer)
    bert_model = db.Column(db.String(120))                   # provenance (FR-12)
    bart_model = db.Column(db.String(120))                   # provenance (FR-13)
    processing_seconds = db.Column(db.Float)                 # NFR-02 / FR-35
    rouge_score = db.Column(db.Float)                        # FR-35 research metric
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    circular = db.relationship("Circular", back_populates="summary")

    def to_dict(self):
        return {
            "id": self.id,
            "circular_id": self.circular_id,
            "summary_text": self.summary_text,
            "entities": self.entities or [],
            "word_count": self.word_count,
            "bert_model": self.bert_model,
            "bart_model": self.bart_model,
            "processing_seconds": self.processing_seconds,
            "rouge_score": self.rouge_score,
        }


class Category(db.Model):
    """CATEGORIES — managed compliance-category taxonomy (admin-editable).

    Replaces the hard-coded category list so administrators can add/remove
    categories, keeping a controlled, reusable taxonomy across circulars.
    """
    __tablename__ = "categories"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {"id": self.id, "name": self.name}


class Classification(db.Model):
    """CLASSIFICATIONS — compliance categories assigned to a circular (FR-18, FR-20).

    Categories are assigned manually by an administrator from the managed
    Category taxonomy; `is_manual` records that (vs any AI suggestion).
    """
    __tablename__ = "classifications"

    # Seed taxonomy — also used to populate the Category table on first run.
    CATEGORIES = (
        "Technology Risk",
        "Anti-Money Laundering",
        "Capital Adequacy",
        "Consumer Protection",
        "General",
    )

    id = db.Column(db.Integer, primary_key=True)
    circular_id = db.Column(db.Integer, db.ForeignKey("circulars.id"), nullable=False)
    category = db.Column(db.String(80), nullable=False)
    confidence = db.Column(db.Float)            # AI confidence (null if manual)
    is_manual = db.Column(db.Boolean, default=False)  # FR-20 override flag
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    circular = db.relationship("Circular", back_populates="classifications")

    def to_dict(self):
        return {"id": self.id, "category": self.category,
                "confidence": self.confidence, "is_manual": self.is_manual}
