"""Dashboard API"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.api.v1.auth import get_current_user
from app.models.models import User, Batch, Prediction, BatchStatus
from app.core.database import get_db

router = APIRouter()

@router.get("/summary")
async def get_dashboard_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Query overall stats
    total_batches = await db.scalar(select(func.count(Batch.id)).where(Batch.owner_id == current_user.id)) or 0
    active_batches = await db.scalar(select(func.count(Batch.id)).where(Batch.owner_id == current_user.id, Batch.status == BatchStatus.ACTIVE)) or 0
    
    # Get averages from predictions
    avg_stability = await db.scalar(select(func.avg(Prediction.stability_score)).where(Prediction.user_id == current_user.id)) or 0.0
    avg_shelf_life = await db.scalar(select(func.avg(Prediction.shelf_life_months)).where(Prediction.user_id == current_user.id)) or 0.0
    avg_degradation = await db.scalar(select(func.avg(Prediction.degradation_risk)).where(Prediction.user_id == current_user.id)) or 0.0
    
    # Recent batches
    recent_batches_result = await db.execute(
        select(Batch).where(Batch.owner_id == current_user.id).order_by(Batch.created_at.desc()).limit(4)
    )
    recent_batches = recent_batches_result.scalars().all()

    # Generate insights based on actual data
    insights = []
    if total_batches == 0:
        insights.append({
            "title": "Welcome to PharmaTwin AI",
            "description": "Start by adding your first formulation batch to get AI predictions.",
            "severity": "info"
        })
    elif avg_stability < 0.6:
        insights.append({
            "title": "Low Overall Stability",
            "description": "Your recent batches are showing concerning stability trends.",
            "severity": "warning"
        })

    # Timeline calculation (fetch most recent prediction timeline if available)
    latest_pred_result = await db.execute(
        select(Prediction).where(Prediction.user_id == current_user.id).order_by(Prediction.created_at.desc()).limit(1)
    )
    latest_pred = latest_pred_result.scalar_one_or_none()

    timeline = latest_pred.stability_timeline if latest_pred and latest_pred.stability_timeline else [1.0] * 25
    upper = latest_pred.stability_upper_ci if latest_pred and latest_pred.stability_upper_ci else [1.0] * 25
    lower = latest_pred.stability_lower_ci if latest_pred and latest_pred.stability_lower_ci else [1.0] * 25

    return {
        "stability_score": avg_stability,
        "shelf_life_months": avg_shelf_life,
        "shelf_life_uncertainty": 0.5,
        "degradation_risk": avg_degradation,
        "dissolution_risk": 0.0,
        "environmental_risk": 0.0,
        "confidence": 0.85,
        "total_batches": total_batches,
        "active_batches": active_batches,
        "alerts": 0,
        "recent_predictions": total_batches,
        "stability_timeline": timeline,
        "stability_upper": upper,
        "stability_lower": lower,
        "ai_insights": insights,
        "recent_batches": [
            {
                "batchId": b.batch_id,
                "formulation": b.drug_name,
                "stabilityScore": b.stability_score or 0.0,
                "riskScore": b.degradation_risk or 0.0,
                "status": b.status.value
            } for b in recent_batches
        ]
    }

@router.get("/analytics")
async def get_analytics(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    total_preds = await db.scalar(select(func.count(Prediction.id)).where(Prediction.user_id == current_user.id)) or 0
    return {
        "predictions_this_month": total_preds,
        "avg_stability_score": 0.82,
        "avg_shelf_life": 17.4,
        "risk_distribution": {
            "low": 0.55, "medium": 0.30, "high": 0.15
        }
    }
