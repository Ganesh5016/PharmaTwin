from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
import logging

from app.core.database import get_db
from app.models.models import User
from app.api.v1.auth import get_current_user
from ml.inference.predictor import PharmaTwinPredictor

router = APIRouter()
logger = logging.getLogger(__name__)

# Singleton predictor
predictor = PharmaTwinPredictor()


# ─── Schemas ────────────────────────────────────────────────────────────────

class PredictionRequest(BaseModel):
    drug_name: str
    dosage_form: str
    drug_load_percent: float
    strength_mg: float
    temperature_c: float = 25.0
    humidity_rh: float = 60.0
    ph_level: float = 7.0
    packaging_type: str = "Blister"
    batch_id: Optional[str] = None
    excipients: Optional[dict] = None
    ich_zone: Optional[str] = "II"


class PredictionResponse(BaseModel):
    prediction_id: str
    shelf_life_months: float
    shelf_life_lower: float
    shelf_life_upper: float
    confidence: float
    stability_score: float
    stability_timeline: List[float]
    stability_upper_ci: List[float]
    stability_lower_ci: List[float]
    degradation_risk: float
    dissolution_profile: List[float]
    failure_probability: float
    feature_importance: dict
    explanation: str
    is_anomaly: bool
    anomaly_score: float
    model_contributions: dict
    created_at: datetime


class PredictionListItem(BaseModel):
    id: str
    drug_name: str
    shelf_life_months: float
    stability_score: float
    degradation_risk: float
    confidence: float
    created_at: datetime


# ─── Endpoints ──────────────────────────────────────────────────────────────

@router.post("/", response_model=PredictionResponse)
async def run_prediction(
    request: PredictionRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
):
    """Run AI prediction ensemble for pharmaceutical stability."""
    try:
        result = predictor.predict(
            drug_name=request.drug_name,
            dosage_form=request.dosage_form,
            drug_load_percent=request.drug_load_percent,
            strength_mg=request.strength_mg,
            temperature_c=request.temperature_c,
            humidity_rh=request.humidity_rh,
            ph_level=request.ph_level,
            packaging_type=request.packaging_type,
            excipients=request.excipients or {},
            ich_zone=request.ich_zone or "II",
        )

        # Save to MongoDB
        db = get_db()
        pred_doc = {
            "user_id": ObjectId(current_user.id),
            "batch_id": request.batch_id,
            "input_params": request.model_dump(),
            "model_type": "ensemble",
            "shelf_life_months": result["shelf_life_months"],
            "shelf_life_lower": result["shelf_life_lower"],
            "shelf_life_upper": result["shelf_life_upper"],
            "confidence": result["confidence"],
            "stability_score": result["stability_score"],
            "stability_timeline": result["stability_timeline"],
            "stability_upper_ci": result["stability_upper_ci"],
            "stability_lower_ci": result["stability_lower_ci"],
            "degradation_risk": result["degradation_risk"],
            "dissolution_profile": result["dissolution_profile"],
            "failure_probability": result["failure_probability"],
            "feature_importance": result["feature_importance"],
            "explanation": result["explanation"],
            "is_anomaly": result["is_anomaly"],
            "anomaly_score": result["anomaly_score"],
            "status": "completed",
            "created_at": datetime.utcnow(),
        }
        insert_result = await db.predictions.insert_one(pred_doc)

        return PredictionResponse(
            prediction_id=str(insert_result.inserted_id),
            **result,
            created_at=pred_doc["created_at"],
        )

    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@router.get("/", response_model=List[PredictionListItem])
async def list_predictions(
    skip: int = 0,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
):
    """List user's predictions."""
    db = get_db()
    cursor = db.predictions.find(
        {"user_id": ObjectId(current_user.id)}
    ).sort("created_at", -1).skip(skip).limit(limit)

    predictions = await cursor.to_list(length=limit)

    return [
        PredictionListItem(
            id=str(p["_id"]),
            drug_name=p.get("input_params", {}).get("drug_name", "Unknown"),
            shelf_life_months=p.get("shelf_life_months", 0),
            stability_score=p.get("stability_score", 0),
            degradation_risk=p.get("degradation_risk", 0),
            confidence=p.get("confidence", 0),
            created_at=p.get("created_at", datetime.utcnow()),
        )
        for p in predictions
    ]


@router.get("/{prediction_id}", response_model=PredictionResponse)
async def get_prediction(
    prediction_id: str,
    current_user: User = Depends(get_current_user),
):
    """Get prediction by ID."""
    db = get_db()
    pred = await db.predictions.find_one({
        "_id": ObjectId(prediction_id),
        "user_id": ObjectId(current_user.id),
    })
    if not pred:
        raise HTTPException(status_code=404, detail="Prediction not found")

    return PredictionResponse(
        prediction_id=str(pred["_id"]),
        shelf_life_months=pred["shelf_life_months"],
        shelf_life_lower=pred["shelf_life_lower"],
        shelf_life_upper=pred["shelf_life_upper"],
        confidence=pred["confidence"],
        stability_score=pred["stability_score"],
        stability_timeline=pred.get("stability_timeline", []),
        stability_upper_ci=pred.get("stability_upper_ci", []),
        stability_lower_ci=pred.get("stability_lower_ci", []),
        degradation_risk=pred["degradation_risk"],
        dissolution_profile=pred.get("dissolution_profile", []),
        failure_probability=pred["failure_probability"],
        feature_importance=pred.get("feature_importance", {}),
        explanation=pred.get("explanation", ""),
        is_anomaly=pred.get("is_anomaly", False),
        anomaly_score=pred.get("anomaly_score", 0),
        model_contributions={},
        created_at=pred.get("created_at", datetime.utcnow()),
    )
