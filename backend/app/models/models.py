"""
Models module - MongoDB version.
Pydantic models used as schemas; data stored as dicts in MongoDB.
"""
import enum


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    RESEARCHER = "researcher"
    USER = "user"


class BatchStatus(str, enum.Enum):
    PENDING = "pending"
    ACTIVE = "active"
    REVIEW = "review"
    PASSED = "passed"
    FAILED = "failed"
    ARCHIVED = "archived"


class User:
    """Lightweight user object hydrated from MongoDB document."""
    def __init__(self, doc: dict):
        self.id = str(doc.get("_id", ""))
        self.firebase_uid = doc.get("firebase_uid", "")
        self.email = doc.get("email", "")
        self.name = doc.get("name", "")
        self.role = doc.get("role", UserRole.RESEARCHER)
        self.is_active = doc.get("is_active", True)
        self.avatar_url = doc.get("avatar_url")
        self.organization = doc.get("organization")
        self.created_at = doc.get("created_at")
        self.updated_at = doc.get("updated_at")
        self.last_login = doc.get("last_login")
