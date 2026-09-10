"""Recommendation read API used by the principal client."""

from typing import Any, List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.models import Recommendation, User
from app.schemas.schemas import RecommendationResponse

router = APIRouter()


@router.get("/", response_model=List[RecommendationResponse])
async def list_recommendations(
    school_id: Optional[UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """List recommendations visible to the current user's school or role."""
    target_school_id = school_id
    if current_user.role in ["TEACHER", "PRINCIPAL"]:
        target_school_id = current_user.school_id

    stmt = select(Recommendation).order_by(Recommendation.created_at.desc())
    if target_school_id:
        stmt = stmt.where(Recommendation.school_id == target_school_id)
    return (await db.execute(stmt)).scalars().all()
