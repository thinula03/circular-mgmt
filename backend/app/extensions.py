"""Shared Flask extension instances.

Kept in a separate module so models and blueprints can import `db` without
creating circular imports with the app factory.
"""
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS

db = SQLAlchemy()
jwt = JWTManager()
cors = CORS()
