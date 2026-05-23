from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, or_
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid

from app.core.database import get_db
from app.models.models import Batch, BatchStatus, User
from app.api.v1.auth import get_current_user

router = APIRouter()


class BatchCreateRequest(BaseModel):
    drug_name: str
    dosage_form: str
    strength_mg: float
    drug_load_percent: float
    batch_size_kg: float
    packaging_type: Optional[str] = "Blister"
    manufacturer: Optional[str] = None
    ich_zone: Optional[str] = "II"
    excipients: Optional[dict] = {}
    notes: Optional[str] = None


class BatchResponse(BaseModel):
    id: str
    batch_id: str
    drug_name: str
    dosage_form: str
    strength_mg: float
    drug_load_percent: float
    batch_size_kg: float
    packaging_type: Optional[str]
    manufacturer: Optional[str]
    status: str
    stability_score: Optional[float]
    degradation_risk: Optional[float]
    predicted_shelf_life_months: Optional[float]
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


def _generate_batch_id() -> str:
    now = datetime.utcnow()
    suffix = str(uuid.uuid4())[:4].upper()
    return f"PT-{now.year}-{now.strftime('%m%d')}-{suffix}"


@router.post("/", response_model=BatchResponse, status_code=201)
async def create_batch(
    request: BatchCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    batch = Batch(
        batch_id=_generate_batch_id(),
        owner_id=current_user.id,
        drug_name=request.drug_name,
        dosage_form=request.dosage_form,
        strength_mg=request.strength_mg,
        drug_load_percent=request.drug_load_percent,
        batch_size_kg=request.batch_size_kg,
        packaging_type=request.packaging_type,
        manufacturer=request.manufacturer,
        excipients=request.excipients or {},
        notes=request.notes,
        status=BatchStatus.PENDING,
    )
    db.add(batch)
    await db.flush()
    await db.refresh(batch)
    return _to_response(batch)


@router.get("/", response_model=List[BatchResponse])
async def list_batches(
    skip: int = 0,
    limit: int = 20,
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(Batch).where(Batch.owner_id == current_user.id)

    if search:
        query = query.where(
            or_(
                Batch.drug_name.ilike(f"%{search}%"),
                Batch.batch_id.ilike(f"%{search}%"),
            )
        )
    if status:
        query = query.where(Batch.status == status)

    query = query.order_by(desc(Batch.created_at)).offset(skip).limit(limit)
    result = await db.execute(query)
    batches = result.scalars().all()
    return [_to_response(b) for b in batches]


@router.get("/{batch_id}", response_model=BatchResponse)
async def get_batch(
    batch_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Batch).where(
            Batch.id == uuid.UUID(batch_id),
            Batch.owner_id == current_user.id,
        )
    )
    batch = result.scalar_one_or_none()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")
    return _to_response(batch)


@router.patch("/{batch_id}/status")
async def update_batch_status(
    batch_id: str,
    status: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Batch).where(
            Batch.id == uuid.UUID(batch_id),
            Batch.owner_id == current_user.id,
        )
    )
    batch = result.scalar_one_or_none()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")

    try:
        batch.status = BatchStatus(status)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid status: {status}")

    return {"message": "Status updated", "batch_id": batch_id, "status": status}


@router.delete("/{batch_id}", status_code=204)
async def delete_batch(
    batch_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Batch).where(
            Batch.id == uuid.UUID(batch_id),
            Batch.owner_id == current_user.id,
        )
    )
    batch = result.scalar_one_or_none()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")
    await db.delete(batch)


def _to_response(b: Batch) -> BatchResponse:
    return BatchResponse(
        id=str(b.id),
        batch_id=b.batch_id,
        drug_name=b.drug_name,
        dosage_form=b.dosage_form,
        strength_mg=b.strength_mg,
        drug_load_percent=b.drug_load_percent,
        batch_size_kg=b.batch_size_kg,
        packaging_type=b.packaging_type,
        manufacturer=b.manufacturer,
        status=b.status.value if b.status else "pending",
        stability_score=b.stability_score,
        degradation_risk=b.degradation_risk,
        predicted_shelf_life_months=b.predicted_shelf_life_months,
        notes=b.notes,
        created_at=b.created_at or datetime.utcnow(),
    )
