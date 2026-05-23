from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.core.config import settings
from app.core.database import connect_db, close_db
from app.api.v1.router import api_router
from app.core.firebase import initialize_firebase

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    logger.info("🚀 PharmaTwin AI Backend starting up...")

    # Initialize Firebase Admin
    initialize_firebase()

    # Connect to MongoDB
    await connect_db()

    logger.info("✅ MongoDB connected")
    logger.info("✅ Firebase Admin SDK initialized")
    logger.info("🧬 PharmaTwin AI is ready!")

    yield

    await close_db()
    logger.info("🛑 PharmaTwin AI shutting down...")


app = FastAPI(
    title="PharmaTwin AI API",
    description="Advanced AI-Powered Pharmaceutical Digital Twin Platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix="/api/v1")


@app.get("/")
async def root():
    return {
        "service": "PharmaTwin AI API",
        "version": "1.0.0",
        "status": "operational",
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "ai_models": "loaded",
        "database": "mongodb",
    }
