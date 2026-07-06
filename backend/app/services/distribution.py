"""Circular distribution & compliance workflow (FR-19, FR-22–FR-26).

When a circular is published, it is routed to the relevant departments based on
its compliance classification, and every employee/manager in those departments
gets an acknowledgement record + an in-app notification + an email.
"""
from datetime import datetime, timedelta

from ..extensions import db
from ..models.identity import User, Department, CircularDepartment
from ..models.engagement import Acknowledgement, Notification
from . import audit, email

# FR-19: map each compliance category to department codes. Empty list => all depts.
CATEGORY_ROUTING = {
    "Anti-Money Laundering": ["COMP", "OPS"],
    "Technology Risk": ["IT"],
    "Capital Adequacy": ["COMP"],
    "Consumer Protection": ["OPS", "COMP"],
    "General": [],  # broadcast to all departments
}

# Roles that must read & acknowledge circulars.
RECIPIENT_ROLES = ("Employee", "Manager")


def route_and_notify(circular, broadcast=False):
    """Route a published circular to departments and notify recipients.

    When `broadcast` is True the circular is sent to ALL departments, overriding
    category-based routing (used by the "Send to all departments" toggle).
    Idempotent: re-running re-computes routing and tops up missing
    acknowledgements/notifications without duplicating them.
    Returns {"departments": [...], "recipient_count": n}.
    """
    categories = [c.category for c in circular.classifications] or ["General"]

    # ---- resolve target departments (FR-19) ----
    codes = set()
    broadcast_all = broadcast
    for cat in categories:
        mapped = CATEGORY_ROUTING.get(cat, [])
        if not mapped:
            broadcast_all = True  # "General" goes everywhere
        codes.update(mapped)

    if broadcast_all or not codes:
        departments = Department.query.all()
    else:
        departments = Department.query.filter(Department.code.in_(codes)).all()
    dept_ids = [d.id for d in departments]

    # ---- record routing in the junction table ----
    CircularDepartment.query.filter_by(circular_id=circular.id).delete()
    for dep in departments:
        db.session.add(CircularDepartment(circular_id=circular.id, department_id=dep.id))

    # ---- recipients: active staff in those departments ----
    recipients = User.query.filter(
        User.is_active.is_(True),
        User.department_id.in_(dept_ids),
        User.role.in_(RECIPIENT_ROLES),
    ).all()

    deadline_txt = (
        circular.ack_deadline.strftime("%d %b %Y") if circular.ack_deadline else "soon"
    )
    for user in recipients:
        # Acknowledgement (FR-24) — one per (circular, user)
        ack = Acknowledgement.query.filter_by(
            circular_id=circular.id, user_id=user.id
        ).first()
        if not ack:
            db.session.add(Acknowledgement(circular_id=circular.id, user_id=user.id))

        # In-app notification (FR-22)
        msg = (f"[{circular.priority}] New circular {circular.circular_number}: "
               f"{circular.title} — acknowledge by {deadline_txt}.")
        db.session.add(Notification(user_id=user.id, circular_id=circular.id, message=msg,
                                    link=f"/circulars/{circular.id}"))

        # Email notification with the summary (FR-23)
        summary_text = circular.summary.summary_text if circular.summary else ""
        email.send_email(
            to=user.email,
            subject=f"New Circular {circular.circular_number}: {circular.title}",
            body=(f"Dear {user.full_name},\n\nA new circular has been published.\n\n"
                  f"Summary:\n{summary_text}\n\n"
                  f"Please acknowledge by {deadline_txt}."),
        )

    db.session.commit()
    audit.record("CIRCULAR_DISTRIBUTED", entity_type="Circular", entity_id=circular.id,
                 detail=f"{len(departments)} dept(s), {len(recipients)} recipient(s)")
    return {
        "departments": [d.name for d in departments],
        "recipient_count": len(recipients),
    }


def run_reminders(window_hours: int = 24):
    """FR-26: remind un-acknowledged staff near/after the deadline; flag overdue.

    Sends a reminder to anyone who hasn't acknowledged a circular whose deadline is
    within `window_hours` (or already passed), and marks overdue acks as late.
    Returns {"reminded": n, "overdue": m}.
    """
    from ..models.circular import Circular  # local import avoids a cycle

    now = datetime.utcnow()
    threshold = now + timedelta(hours=window_hours)
    reminded = overdue = 0

    pending = (
        db.session.query(Acknowledgement, Circular)
        .join(Circular, Circular.id == Acknowledgement.circular_id)
        .filter(
            Acknowledgement.status != "Acknowledged",
            Circular.ack_deadline.isnot(None),
            Circular.ack_deadline <= threshold,
        )
        .all()
    )

    for ack, circular in pending:
        if circular.ack_deadline < now and not ack.is_late:
            ack.is_late = True          # FR-25 overdue flag
            overdue += 1
        user = User.query.get(ack.user_id)
        if not user:
            continue
        db.session.add(Notification(
            user_id=user.id, circular_id=circular.id,
            message=(f"Reminder: please acknowledge circular "
                     f"{circular.circular_number} — {circular.title}."),
            link=f"/circulars/{circular.id}",
        ))
        email.send_email(
            to=user.email,
            subject=f"Reminder: acknowledge Circular {circular.circular_number}",
            body=(f"Dear {user.full_name},\n\nThis is a reminder to acknowledge "
                  f"circular {circular.circular_number} ({circular.title})."),
        )
        reminded += 1

    db.session.commit()
    audit.record("REMINDERS_SENT", entity_type="Acknowledgement", entity_id=None,
                 detail=f"reminded={reminded}, overdue={overdue}")
    return {"reminded": reminded, "overdue": overdue}
