"""Environment-driven configuration (dev / prod).

All secrets and the database URL come from the environment (.env), so the same
code runs on SQLite during development and MySQL 8.0 for the thesis deployment.
"""
import os
from datetime import timedelta

from dotenv import load_dotenv

# Load backend/.env BEFORE the Config class body reads os.getenv(), otherwise
# values default before the file is parsed.
_BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(_BACKEND_ROOT, ".env"))


class Config:
    # ---- Flask core ----
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-change-me")

    # ---- Database ----
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL", "sqlite:///circular_management.sqlite3"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # ---- JWT (FR-01 auth, FR-03 30-min session) ----
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "dev-jwt-change-me")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(
        minutes=int(os.getenv("JWT_ACCESS_MINUTES", "30"))
    )

    # ---- File upload (FR-06, FR-09) ----
    UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", "uploads")
    MAX_UPLOAD_MB = int(os.getenv("MAX_UPLOAD_MB", "20"))
    MAX_CONTENT_LENGTH = int(os.getenv("MAX_UPLOAD_MB", "20")) * 1024 * 1024

    # ---- AI models (NFR-08 local inference) ----
    SPACY_MODEL = os.getenv("SPACY_MODEL", "en_core_web_sm")
    BERT_MODEL = os.getenv("BERT_MODEL", "bert-base-uncased")
    BART_MODEL = os.getenv("BART_MODEL", "facebook/bart-large-cnn")
    BART_FALLBACK_MODEL = os.getenv(
        "BART_FALLBACK_MODEL", "sshleifer/distilbart-cnn-12-6"
    )
    SBERT_MODEL = os.getenv("SBERT_MODEL", "all-MiniLM-L6-v2")
    MODEL_CACHE_DIR = os.getenv("MODEL_CACHE_DIR", "model_cache")

    # ---- CORS ----
    FRONTEND_ORIGIN = os.getenv("FRONTEND_ORIGIN", "http://localhost:5173")
