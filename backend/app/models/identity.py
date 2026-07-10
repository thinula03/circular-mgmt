"""Identity & organisation tables: USERS, DEPARTMENTS, CIRCULAR_DEPARTMENTS."""
from datetime import datetime
from ..extensions import db


class Department(db.Model):
    """DEPARTMENTS — organisational units circulars are routed to."""
    __tablename__ = "departments"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), unique=True, nullable=False)
    code = db.Column(db.String(20), unique=True, nullable=False)
    description = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    users = db.relationship("User", back_populates="department")

    def to_dict(self):
        return {"id": self.id, "name": self.name, "code": self.code,
                "description": self.description}


class User(db.Model):
    """USERS — identity, authentication, roles (Administrator/Manager/Employee).

    Soft delete via `is_active` preserves referential integrity in historical
    acknowledgement/audit records (thesis §4.3).
    """
    __tablename__ = "users"

    ROLES = ("Administrator", "Manager", "Compliance Officer", "Employee")

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    full_name = db.Column(db.String(120), nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)  # bcrypt, NFR-06
    role = db.Column(db.String(20), nullable=False, default="Employee")
    department_id = db.Column(db.Integer, db.ForeignKey("departments.id"))
    is_active = db.Column(db.Boolean, default=True, nullable=False)  # soft delete
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)

    department = db.relationship("Department", back_populates="users")
    acknowledgements = db.relationship("Acknowledgement", back_populates="user")

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "full_name": self.full_name,
            "role": self.role,
            "department_id": self.department_id,
            "department": self.department.name if self.department else None,
            "is_active": self.is_active,
        }


class CircularDepartment(db.Model):
    """CIRCULAR_DEPARTMENTS — junction for many-to-many circular↔department routing."""
    __tablename__ = "circular_departments"

    circular_id = db.Column(db.Integer, db.ForeignKey("circulars.id"), primary_key=True)
    department_id = db.Column(db.Integer, db.ForeignKey("departments.id"), primary_key=True)
    routed_at = db.Column(db.DateTime, default=datetime.utcnow)
