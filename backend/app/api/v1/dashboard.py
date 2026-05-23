"""Dashboard API - MongoDB version"""
from fastapi import APIRouter, Depends
from bson import ObjectId
from app.api.v1.auth import get_current_user
from app.models.models import User, BatchStatus
from app.core.database import get_db

router = APIRouter()


@router.get("/summary")
async def get_dashboard_summary(
    current_user: User = Depends(get_current_user),
):
    db = get_db()
    user_oid = ObjectId(current_user.id)

    # Count batches
    total_batches = await db.batches.count_documents({"owner_id": user_oid})
    active_batches = await db.batches.count_documents({"owner_id": user_oid, "status": BatchStatus.ACTIVE})

    # Get prediction averages via aggregation
    pipeline = [
        {"$match": {"user_id": user_oid}},
        {"$group": {
            "_id": None,
            "avg_stability": {"$avg": "$stability_score"},
            "avg_shelf_life": {"$avg": "$shelf_life_months"},
            "avg_degradation": {"$avg": "$degradation_risk"},
            "count": {"$sum": 1},
        }}
    ]
    agg_result = await db.predictions.aggregate(pipeline).to_list(1)
    stats = agg_result[0] if agg_result else {}

    avg_stability = stats.get("avg_stability", 0.0) or 0.0
    avg_shelf_life = stats.get("avg_shelf_life", 0.0) or 0.0
    avg_degradation = stats.get("avg_degradation", 0.0) or 0.0

    # Recent batches
    recent_batches = await db.batches.find(
        {"owner_id": user_oid}
    ).sort("created_at", -1).limit(4).to_list(4)

    # Latest prediction timeline
    latest_pred = await db.predictions.find_one(
        {"user_id": user_oid},
        sort=[("created_at", -1)]
    )

    timeline = latest_pred.get("stability_timeline", [1.0] * 25) if latest_pred else [1.0] * 25
    upper = latest_pred.get("stability_upper_ci", [1.0] * 25) if latest_pred else [1.0] * 25
    lower = latest_pred.get("stability_lower_ci", [1.0] * 25) if latest_pred else [1.0] * 25

    # Generate insights
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
                "batchId": b.get("batch_id", ""),
                "formulation": b.get("drug_name", ""),
                "stabilityScore": b.get("stability_score", 0.0) or 0.0,
                "riskScore": b.get("degradation_risk", 0.0) or 0.0,
                "status": b.get("status", "pending"),
            } for b in recent_batches
        ]
    }


@router.get("/analytics")
async def get_analytics(
    current_user: User = Depends(get_current_user),
):
    db = get_db()
    total_preds = await db.predictions.count_documents({"user_id": ObjectId(current_user.id)})
    return {
        "predictions_this_month": total_preds,
        "avg_stability_score": 0.82,
        "avg_shelf_life": 17.4,
        "risk_distribution": {
            "low": 0.55, "medium": 0.30, "high": 0.15
        }
    }
