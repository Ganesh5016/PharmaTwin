from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
import uuid

from app.core.database import get_db
from app.models.models import User, BatchStatus
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


def _generate_batch_id() -> str:
    now = datetime.utcnow()
    suffix = str(uuid.uuid4())[:4].upper()
    return f"PT-{now.year}-{now.strftime('%m%d')}-{suffix}"


def _to_response(b: dict) -> BatchResponse:
    return BatchResponse(
        id=str(b["_id"]),
        batch_id=b.get("batch_id", ""),
        drug_name=b.get("drug_name", ""),
        dosage_form=b.get("dosage_form", ""),
        strength_mg=b.get("strength_mg", 0),
        drug_load_percent=b.get("drug_load_percent", 0),
        batch_size_kg=b.get("batch_size_kg", 0),
        packaging_type=b.get("packaging_type"),
        manufacturer=b.get("manufacturer"),
        status=b.get("status", "pending"),
        stability_score=b.get("stability_score"),
        degradation_risk=b.get("degradation_risk"),
        predicted_shelf_life_months=b.get("predicted_shelf_life_months"),
        notes=b.get("notes"),
        created_at=b.get("created_at", datetime.utcnow()),
    )


@router.post("/", response_model=BatchResponse, status_code=201)
async def create_batch(
    request: BatchCreateRequest,
    current_user: User = Depends(get_current_user),
):
    db = get_db()
    batch_doc = {
        "batch_id": _generate_batch_id(),
        "owner_id": ObjectId(current_user.id),
        "drug_name": request.drug_name,
        "dosage_form": request.dosage_form,
        "strength_mg": request.strength_mg,
        "drug_load_percent": request.drug_load_percent,
        "batch_size_kg": request.batch_size_kg,
        "packaging_type": request.packaging_type,
        "manufacturer": request.manufacturer,
        "excipients": request.excipients or {},
        "notes": request.notes,
        "status": BatchStatus.PENDING,
        "created_at": datetime.utcnow(),
    }
    result = await db.batches.insert_one(batch_doc)
    batch_doc["_id"] = result.inserted_id
    return _to_response(batch_doc)


@router.get("/", response_model=List[BatchResponse])
async def list_batches(
    skip: int = 0,
    limit: int = 20,
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
):
    db = get_db()
    query = {"owner_id": ObjectId(current_user.id)}

    if search:
        query["$or"] = [
            {"drug_name": {"$regex": search, "$options": "i"}},
            {"batch_id": {"$regex": search, "$options": "i"}},
        ]
    if status:
        query["status"] = status

    cursor = db.batches.find(query).sort("created_at", -1).skip(skip).limit(limit)
    batches = await cursor.to_list(length=limit)
    return [_to_response(b) for b in batches]


@router.get("/{batch_id}", response_model=BatchResponse)
async def get_batch(
    batch_id: str,
    current_user: User = Depends(get_current_user),
):
    db = get_db()
    batch = await db.batches.find_one({
        "_id": ObjectId(batch_id),
        "owner_id": ObjectId(current_user.id),
    })
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")
    return _to_response(batch)


@router.patch("/{batch_id}/status")
async def update_batch_status(
    batch_id: str,
    status: str,
    current_user: User = Depends(get_current_user),
):
    db = get_db()
    result = await db.batches.update_one(
        {"_id": ObjectId(batch_id), "owner_id": ObjectId(current_user.id)},
        {"$set": {"status": status, "updated_at": datetime.utcnow()}}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Batch not found")
    return {"message": "Status updated", "batch_id": batch_id, "status": status}


@router.delete("/{batch_id}", status_code=204)
async def delete_batch(
    batch_id: str,
    current_user: User = Depends(get_current_user),
):
    db = get_db()
    result = await db.batches.delete_one({
        "_id": ObjectId(batch_id),
        "owner_id": ObjectId(current_user.id),
    })
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Batch not found")
