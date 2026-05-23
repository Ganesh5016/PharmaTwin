from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid
import logging

from app.core.database import get_db
from app.models.models import Prediction, User
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

    class Config:
        from_attributes = True


# ─── Endpoints ──────────────────────────────────────────────────────────────

@router.post("/", response_model=PredictionResponse)
async def run_prediction(
    request: PredictionRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
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

        # Save to DB
        pred = Prediction(
            batch_id=uuid.UUID(request.batch_id) if request.batch_id else None,
            user_id=current_user.id,
            input_params=request.model_dump(),
            model_type="ensemble",
            shelf_life_months=result["shelf_life_months"],
            shelf_life_lower=result["shelf_life_lower"],
            shelf_life_upper=result["shelf_life_upper"],
            confidence=result["confidence"],
            stability_score=result["stability_score"],
            stability_timeline=result["stability_timeline"],
            stability_upper_ci=result["stability_upper_ci"],
            stability_lower_ci=result["stability_lower_ci"],
            degradation_risk=result["degradation_risk"],
            dissolution_profile=result["dissolution_profile"],
            failure_probability=result["failure_probability"],
            feature_importance=result["feature_importance"],
            explanation=result["explanation"],
            is_anomaly=result["is_anomaly"],
            anomaly_score=result["anomaly_score"],
            status="completed",
        )
        db.add(pred)
        await db.flush()

        return PredictionResponse(
            prediction_id=str(pred.id),
            **result,
            created_at=pred.created_at or datetime.utcnow(),
        )

    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@router.get("/", response_model=List[PredictionListItem])
async def list_predictions(
    skip: int = 0,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List user's predictions."""
    result = await db.execute(
        select(Prediction)
        .where(Prediction.user_id == current_user.id)
        .order_by(desc(Prediction.created_at))
        .offset(skip)
        .limit(limit)
    )
    predictions = result.scalars().all()

    return [
        PredictionListItem(
            id=str(p.id),
            drug_name=p.input_params.get("drug_name", "Unknown"),
            shelf_life_months=p.shelf_life_months or 0,
            stability_score=p.stability_score or 0,
            degradation_risk=p.degradation_risk or 0,
            confidence=p.confidence or 0,
            created_at=p.created_at,
        )
        for p in predictions
    ]


@router.get("/{prediction_id}", response_model=PredictionResponse)
async def get_prediction(
    prediction_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get prediction by ID."""
    result = await db.execute(
        select(Prediction).where(
            Prediction.id == uuid.UUID(prediction_id),
            Prediction.user_id == current_user.id,
        )
    )
    pred = result.scalar_one_or_none()
    if not pred:
        raise HTTPException(status_code=404, detail="Prediction not found")

    return PredictionResponse(
        prediction_id=str(pred.id),
        shelf_life_months=pred.shelf_life_months,
        shelf_life_lower=pred.shelf_life_lower,
        shelf_life_upper=pred.shelf_life_upper,
        confidence=pred.confidence,
        stability_score=pred.stability_score,
        stability_timeline=pred.stability_timeline or [],
        stability_upper_ci=pred.stability_upper_ci or [],
        stability_lower_ci=pred.stability_lower_ci or [],
        degradation_risk=pred.degradation_risk,
        dissolution_profile=pred.dissolution_profile or [],
        failure_probability=pred.failure_probability,
        feature_importance=pred.feature_importance or {},
        explanation=pred.explanation or "",
        is_anomaly=pred.is_anomaly,
        anomaly_score=pred.anomaly_score or 0,
        model_contributions={},
        created_at=pred.created_at,
    )
