"""Phase 0 verification: app imports, MySQL connects, /health returns 200."""
from sqlalchemy import text

from app import create_app
from app.extensions import db

app = create_app()

with app.test_client() as client:
    resp = client.get("/health")
    print("HEALTH:", resp.status_code, resp.get_json())

with app.app_context():
    count = db.session.execute(
        text(
            "SELECT COUNT(*) FROM information_schema.tables "
            "WHERE table_schema = 'circular_management'"
        )
    ).scalar()
    print("TABLES_IN_DB:", count)
