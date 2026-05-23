"""Reports API"""
from fastapi import APIRouter, Depends
from app.api.v1.auth import get_current_user
from app.models.models import User

router = APIRouter()

@router.get("/")
async def list_reports(current_user: User = Depends(get_current_user)):
    return {"reports": [], "total": 0}

@router.post("/generate")
async def generate_report(
    batch_id: str,
    report_type: str = "stability",
    current_user: User = Depends(get_current_user),
):
    return {
        "report_id": "rpt-001",
        "status": "generated",
        "download_url": f"/reports/download/rpt-001",
        "message": f"Report '{report_type}' generated successfully",
    }
