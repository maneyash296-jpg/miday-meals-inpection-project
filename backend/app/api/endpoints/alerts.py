"""NutriGuard AI — Alerts API Endpoints."""

from typing import Any, List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.models import Alert

router = APIRouter()


@router.get("/")
async def list_alerts(
    limit: int = Query(50, ge=1, le=200),
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
) -> Any:
    """List all alerts, optionally filtered by status."""
    stmt = select(Alert).order_by(Alert.created_at.desc()).limit(limit)
    result = await db.execute(stmt)
    alerts = result.scalars().all()

    def fmt(a):
        return {
            "id": str(a.id),
            "school_id": str(a.school_id) if a.school_id else None,
            "ration_shop_id": str(a.ration_shop_id) if a.ration_shop_id else None,
            "alert_type": a.alert_type,
            "severity": a.severity.value if hasattr(a.severity, "value") else str(a.severity),
            "title": a.title,
            "message": a.message,
            "source": a.source,
            "status": a.status.value if hasattr(a.status, "value") else str(a.status),
            "created_at": a.created_at.isoformat() if a.created_at else None,
            "resolved_at": a.resolved_at.isoformat() if a.resolved_at else None,
        }

    items = [fmt(a) for a in alerts]
    if status:
        items = [i for i in items if i["status"].upper() == status.upper()]
    return items
