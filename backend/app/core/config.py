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

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://pharmatwin:pharmatwin123@localhost:5432/pharmatwin_db"

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "firebase-credentials.json"
    FIREBASE_PROJECT_ID: str = "pharmatwin-ai"

    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://10.0.2.2",
        "http://10.0.2.2:8000",
        "*",  # For development - restrict in production
    ]

    # ML Models
    MODEL_CACHE_DIR: str = "./ml/saved_models"
    LSTM_MODEL_PATH: str = "./ml/saved_models/lstm_stability.h5"
    XGBOOST_MODEL_PATH: str = "./ml/saved_models/xgb_degradation.pkl"
    AUTOENCODER_MODEL_PATH: str = "./ml/saved_models/autoencoder.h5"

    # Storage
    UPLOAD_DIR: str = "./uploads"
    REPORT_DIR: str = "./reports"

    # Redis (optional - for caching)
    REDIS_URL: str = "redis://localhost:6379"

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
