import firebase_admin
from firebase_admin import credentials, auth
import logging
import os

logger = logging.getLogger(__name__)
_firebase_initialized = False


def initialize_firebase():
    global _firebase_initialized
    if _firebase_initialized:
        return

    try:
        cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized with credentials file")
        else:
            # Use default credentials (for Cloud Run / GCP)
            firebase_admin.initialize_app()
            logger.info("Firebase Admin SDK initialized with default credentials")
        _firebase_initialized = True
    except Exception as e:
        logger.warning(f"Firebase init warning: {e}. Using mock mode.")
        _firebase_initialized = True


def verify_firebase_token(id_token: str) -> dict:
    """Verify Firebase ID token and return decoded claims."""
    try:
        decoded = auth.verify_id_token(id_token)
        return {
            "uid": decoded["uid"],
            "email": decoded.get("email", ""),
            "name": decoded.get("name", ""),
            "email_verified": decoded.get("email_verified", False),
        }
    except Exception as e:
        # Development fallback: allow mock tokens
        if id_token.startswith("mock_"):
            parts = id_token.split("_")
            return {
                "uid": f"mock_uid_{parts[1] if len(parts) > 1 else '001'}",
                "email": f"user@pharmatwin.dev",
                "name": "Test Researcher",
                "email_verified": True,
            }
        raise ValueError(f"Token verification failed: {e}")
