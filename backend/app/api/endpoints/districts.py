"""NutriGuard AI — Districts API Endpoints.

Handles district-level dashboard, school aggregation, and analytics
for district officers monitoring the PM POSHAN scheme.
"""

from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
import uuid as _uuid

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.models import (
    District, School, RationShop, MealRecord, Alert, WasteRecord,
    Prediction, Recommendation, User
)

router = APIRouter()


@router.get("/")
async def list_districts(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """List all districts."""
    result = await db.execute(select(District))
    districts = result.scalars().all()
    return [
        {
            "id": str(d.id),
            "name": d.name,
            "code": d.code,
            "state": d.state,
            "created_at": d.created_at.isoformat() if d.created_at else None,
        }
        for d in districts
    ]


@router.get("/dashboard")
async def get_district_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Get dashboard data for the district officer's district."""
    district_id = current_user.district_id

    district = None
    if district_id:
        dist_uuid = _uuid.UUID(district_id) if isinstance(district_id, str) else district_id
        result = await db.execute(select(District).where(District.id == dist_uuid))
        district = result.scalars().first()

    # Build query filters
    school_stmt = select(School)
    shop_stmt = select(RationShop)
    if district and district_id:
        dist_uuid = _uuid.UUID(district_id) if isinstance(district_id, str) else district_id
        school_stmt = school_stmt.where(School.district_id == dist_uuid)
        shop_stmt = shop_stmt.where(RationShop.district_id == dist_uuid)

    schools_result = await db.execute(school_stmt)
    schools = schools_result.scalars().all()

    shops_result = await db.execute(shop_stmt)
    shops = shops_result.scalars().all()

    # Fetch recent meals across district schools
    school_ids = [s.id for s in schools]
    meals_list = []
    total_waste = 0.0
    avg_compliance = 0.0

    if school_ids:
        meal_result = await db.execute(
            select(MealRecord).where(
                MealRecord.school_id.in_(school_ids)
            ).order_by(MealRecord.created_at.desc()).limit(50)
        )
        meals_list = meal_result.scalars().all()

        scored = [m for m in meals_list if m.overall_score is not None]
        if scored:
            avg_compliance = sum(m.overall_score for m in scored) / len(scored)

        waste_result = await db.execute(
            select(WasteRecord).where(WasteRecord.school_id.in_(school_ids))
        )
        waste_records = waste_result.scalars().all()
        total_waste = sum(w.quantity for w in waste_records)

    # Fetch active alerts
    alert_stmt = select(Alert).order_by(Alert.created_at.desc()).limit(10)
    alert_result = await db.execute(alert_stmt)
    alerts = alert_result.scalars().all()
    alerts_list = [
        {
            "id": str(a.id),
            "title": a.title,
            "message": a.message,
            "severity": a.severity.value if hasattr(a.severity, "value") else str(a.severity),
            "alert_type": a.alert_type,
            "school_id": str(a.school_id) if a.school_id else None,
            "ration_shop_id": str(a.ration_shop_id) if a.ration_shop_id else None,
            "status": a.status.value if hasattr(a.status, "value") else str(a.status),
            "created_at": a.created_at.isoformat() if a.created_at else None,
        }
        for a in alerts
    ]

    # High-risk schools: schools with low compliance
    high_risk_schools = []
    for s in schools:
        school_meals = [m for m in meals_list if m.school_id == s.id]
        if school_meals:
            school_avg = sum(m.overall_score or 0 for m in school_meals) / len(school_meals)
            if school_avg < 70:
                high_risk_schools.append({
                    "id": str(s.id),
                    "name": s.name,
                    "school_code": s.school_code,
                    "compliance_score": round(school_avg, 1),
                    "waste_kg": 0,
                })

    # School map coordinates
    school_coords = [
        {
            "id": str(s.id),
            "name": s.name,
            "latitude": s.latitude,
            "longitude": s.longitude,
            "student_count": s.student_count,
        }
        for s in schools
        if s.latitude and s.longitude
    ]

    total_students = sum(s.student_count for s in schools)

    return {
        "district": {
            "id": str(district.id),
            "name": district.name,
            "code": district.code,
            "state": district.state,
        } if district else None,
        "total_schools": len(schools),
        "total_ration_shops": len(shops),
        "total_students": total_students,
        "meals_monitored_today": len(meals_list),
        "avg_compliance": round(avg_compliance, 1),
        "total_waste_kg": round(total_waste, 2),
        "resource_savings": round(total_waste * 45, 2),  # ~₹45/kg estimated
        "high_risk_schools": high_risk_schools,
        "high_risk_ration_shops": [
            {
                "id": str(rs.id),
                "name": rs.name,
                "risk_score": rs.current_risk_score,
            }
            for rs in shops
            if (rs.current_risk_score or 0) > 0.5
        ],
        "alerts": alerts_list,
        "school_coordinates": school_coords,
        "waste_trend": [],
        "compliance_trend": [],
    }


@router.get("/{district_id}")
async def get_district(
    district_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Get a specific district by ID."""
    result = await db.execute(select(District).where(District.id == district_id))
    district = result.scalars().first()
    if not district:
        raise HTTPException(status_code=404, detail="District not found")
    return {
        "id": str(district.id),
        "name": district.name,
        "code": district.code,
        "state": district.state,
        "created_at": district.created_at.isoformat() if district.created_at else None,
    }


@router.get("/{district_id}/schools")
async def get_district_schools(
    district_id: UUID,
    q: Optional[str] = Query(None, description="Search schools"),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Get all schools in a district, optionally filtered."""
    from sqlalchemy import or_
    stmt = select(School).where(School.district_id == district_id)
    if q:
        pattern = f"%{q.strip()}%"
        stmt = stmt.where(
            or_(
                School.name.ilike(pattern),
                School.school_code.ilike(pattern),
            )
        )
    result = await db.execute(stmt)
    schools = result.scalars().all()
    return [
        {
            "id": str(s.id),
            "name": s.name,
            "school_code": s.school_code,
            "address": s.address,
            "student_count": s.student_count,
            "active": s.active,
        }
        for s in schools
    ]
