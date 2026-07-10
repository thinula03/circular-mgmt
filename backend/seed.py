"""Seed the database with demo data so every screen is immediately demoable.

Run:  python seed.py
Creates 3 departments, 3 users (one per role), and one fully-processed sample
circular (summary + classification + acknowledgements) plus a FAISS stub entry.

Demo credentials (password = 'password123' for all):
    admin    / Administrator
    manager  / Manager
    employee / Employee
"""
from datetime import datetime, timedelta

from app import create_app
from app.extensions import db
from app.models.identity import User, Department, CircularDepartment
from app.models.circular import Circular, Summary, Classification
from app.models.engagement import Acknowledgement, Notification
from app.services.security import hash_password
from app.ai import get_index

SAMPLE_TEXT = (
    "Circular No. 03/2024 issued by the Central Bank of Sri Lanka on 12/03/2024 "
    "directs all licensed commercial banks to strengthen anti-money laundering "
    "controls. Banks must complete enhanced customer due diligence for all "
    "accounts exceeding Rs. 5,000,000 by 30/06/2024. Suspicious transaction "
    "reports must be filed within 24 hours. Non-compliance may attract penalties "
    "under the Financial Transactions Reporting Act. Banks shall designate a "
    "compliance officer responsible for monitoring KYC adherence and quarterly "
    "reporting to the Central Bank."
)


def run():
    app = create_app()
    with app.app_context():
        db.create_all()
        if User.query.first():
            print("Database already seeded — skipping.")
            return

        # ---- departments ----
        compliance = Department(name="Compliance", code="COMP",
                                description="Regulatory compliance unit")
        it = Department(name="Information Technology", code="IT",
                        description="IT and systems")
        ops = Department(name="Operations", code="OPS", description="Branch operations")
        db.session.add_all([compliance, it, ops])
        db.session.flush()

        # ---- users (one per role) ----
        pw = hash_password("password123")
        admin = User(username="admin", email="admin@bank.lk", full_name="System Admin",
                     password_hash=pw, role="Administrator", department_id=it.id)
        manager = User(username="manager", email="manager@bank.lk",
                       full_name="Compliance Manager", password_hash=pw,
                       role="Manager", department_id=compliance.id)
        employee = User(username="employee", email="employee@bank.lk",
                        full_name="Branch Employee", password_hash=pw,
                        role="Employee", department_id=ops.id)
        officer = User(username="officer", email="officer@bank.lk",
                       full_name="Compliance Officer", password_hash=pw,
                       role="Compliance Officer", department_id=compliance.id)
        db.session.add_all([admin, manager, employee, officer])
        db.session.flush()

        # ---- sample circular (fully processed) ----
        circular = Circular(
            circular_number="03/2024",
            title="Enhanced AML Controls for Licensed Commercial Banks",
            issue_date=datetime(2024, 3, 12).date(),
            file_size_kb=512,
            extracted_text=SAMPLE_TEXT,
            priority="High",
            status="published",
            ack_deadline=datetime.utcnow() + timedelta(days=7),
            uploaded_by=admin.id,
            published_at=datetime.utcnow(),
        )
        db.session.add(circular)
        db.session.flush()

        db.session.add(CircularDepartment(circular_id=circular.id,
                                          department_id=compliance.id))
        db.session.add(CircularDepartment(circular_id=circular.id,
                                          department_id=ops.id))

        summary = Summary(
            circular_id=circular.id,
            summary_text=(
                "CBSL Circular 03/2024 requires licensed commercial banks to "
                "strengthen anti-money laundering controls. Enhanced due diligence "
                "is mandatory for accounts over Rs. 5,000,000 by 30 June 2024, with "
                "suspicious transactions reported within 24 hours. Each bank must "
                "appoint a compliance officer for KYC monitoring and quarterly CBSL "
                "reporting."
            ),
            entities=[
                {"text": "12/03/2024", "label": "DATE"},
                {"text": "Rs. 5,000,000", "label": "MONEY"},
                {"text": "30/06/2024", "label": "DATE"},
                {"text": "Circular No. 03/2024", "label": "REGULATION"},
            ],
            word_count=58,
            bert_model="stub",
            bart_model="stub",
            processing_seconds=0.4,
        )
        db.session.add(summary)
        db.session.add(Classification(circular_id=circular.id,
                                      category="Anti-Money Laundering",
                                      confidence=0.92, is_manual=False))

        # ---- acknowledgements (one per status for colour demo) ----
        db.session.add(Acknowledgement(circular_id=circular.id, user_id=employee.id,
                                       status="Unread"))
        db.session.add(Notification(user_id=employee.id, circular_id=circular.id,
                                    message="New circular published: AML Controls 03/2024"))

        db.session.commit()

        # ---- seed the vector index stub ----
        index = get_index(app.config)
        index.chunk_and_embed("03/2024", SAMPLE_TEXT, section="Full text")

        print("Seeded: 3 departments, 3 users, 1 sample circular.")
        print("Login with admin / manager / employee  (password: password123)")


if __name__ == "__main__":
    run()
