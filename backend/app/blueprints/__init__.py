"""Flask blueprints (REST API). Registered by the app factory."""
from .auth import auth_bp
from .users import users_bp
from .circulars import circulars_bp
from .summaries import summaries_bp
from .dashboard import dashboard_bp
from .chatbot import chatbot_bp
from .notifications import notifications_bp

ALL_BLUEPRINTS = (
    (auth_bp, "/api/auth"),
    (users_bp, "/api/users"),
    (circulars_bp, "/api/circulars"),
    (summaries_bp, "/api/summaries"),
    (dashboard_bp, "/api/dashboard"),
    (chatbot_bp, "/api/chatbot"),
    (notifications_bp, "/api/notifications"),
)
