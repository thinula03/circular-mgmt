"""Application factory.

Usage:
    from app import create_app
    app = create_app()
"""
import os

from flask import Flask, jsonify
from dotenv import load_dotenv

from .config import Config
from .extensions import db, jwt, cors


def create_app(config_class=Config):
    # Load .env from the backend root (one level up from this package)
    backend_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    load_dotenv(os.path.join(backend_root, ".env"))

    app = Flask(__name__)
    app.config.from_object(config_class)

    # Ensure upload folder exists
    upload_dir = os.path.join(backend_root, app.config["UPLOAD_FOLDER"])
    os.makedirs(upload_dir, exist_ok=True)
    app.config["UPLOAD_FOLDER"] = upload_dir

    # ---- extensions ----
    db.init_app(app)
    jwt.init_app(app)
    cors.init_app(app, resources={r"/api/*": {"origins": app.config["FRONTEND_ORIGIN"]}})

    # ---- models (register with SQLAlchemy) ----
    from . import models  # noqa: F401

    # ---- blueprints ----
    from .blueprints import ALL_BLUEPRINTS
    for blueprint, prefix in ALL_BLUEPRINTS:
        app.register_blueprint(blueprint, url_prefix=prefix)

    # ---- oversized upload (FR-09: reject files over 20MB) ----
    @app.errorhandler(413)
    def too_large(_err):
        return jsonify({
            "error": f"File exceeds the {app.config['MAX_UPLOAD_MB']}MB limit."
        }), 413

    # ---- health check (Phase 0 verification) ----
    @app.get("/health")
    def health():
        return jsonify({
            "status": "ok",
            "service": "Smart Circular Summarization & Management System",
            "database": app.config["SQLALCHEMY_DATABASE_URI"].split("://")[0],
        })

    # Create tables on first run when using SQLite dev database
    with app.app_context():
        if app.config["SQLALCHEMY_DATABASE_URI"].startswith("sqlite"):
            db.create_all()

    return app
