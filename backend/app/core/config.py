from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    # App
    APP_NAME: str = "PharmaTwin AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    SECRET_KEY: str = "your-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # MongoDB
    MONGODB_URL: str = "mongodb+srv://pharmatwin:pharmatwin123@cluster0.mongodb.net/?retryWrites=true&w=majority"
    MONGODB_DB_NAME: str = "pharmatwin_db"

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "firebase-credentials.json"
    FIREBASE_PROJECT_ID: str = "pharmatwin-cd4eb"

    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://10.0.2.2",
        "http://10.0.2.2:8000",
        "*",
    ]

    # ML Models
    MODEL_CACHE_DIR: str = "./ml/saved_models"

    # Storage
    UPLOAD_DIR: str = "./uploads"
    REPORT_DIR: str = "./reports"

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
