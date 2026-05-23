from fastapi import APIRouter
from app.api.v1 import auth, predictions, batches, simulations, reports, dashboard, admin, alternatives, chat

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(predictions.router, prefix="/predictions", tags=["AI Predictions"])
api_router.include_router(alternatives.router, prefix="/alternatives", tags=["Drug Alternatives"])
api_router.include_router(chat.router, prefix="/chat", tags=["AI Chat Assistant"])
api_router.include_router(batches.router, prefix="/batches", tags=["Batch Management"])
api_router.include_router(simulations.router, prefix="/simulations", tags=["Simulations"])
api_router.include_router(reports.router, prefix="/reports", tags=["Reports"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])
api_router.include_router(admin.router, prefix="/admin", tags=["Admin"])
