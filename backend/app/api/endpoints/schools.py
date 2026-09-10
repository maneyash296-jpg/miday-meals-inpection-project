"""NutriGuard AI — Schools API."""

from typing import Any, List
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.models import School, User, Meal, FoodWaste, Inventory, FoodItem, Recommendation, Alert
from app.schemas.schemas import SchoolResponse, SchoolCreate, TeacherDashboard, PrincipalDashboard

router = APIRouter()


@router.get("/", response_model=List[SchoolResponse])
async def get_schools(
    limit: int = 200,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Get all schools (Admin/District only) or specific school for Teacher/Principal."""
    import uuid as _uuid
    role = current_user.get("role", "") if isinstance(current_user, dict) else getattr(current_user, "role", "")
    school_id = current_user.get("school_id") if isinstance(current_user, dict) else getattr(current_user, "school_id", None)
    district_id = current_user.get("district_id") if isinstance(current_user, dict) else getattr(current_user, "district_id", None)

    if role in ["TEACHER", "PRINCIPAL"]:
        if not school_id:
            return []
        sid = _uuid.UUID(school_id) if isinstance(school_id, str) else school_id
        result = await db.execute(select(School).where(School.id == sid))
    elif role == "DISTRICT_OFFICER" and district_id:
        did = _uuid.UUID(district_id) if isinstance(district_id, str) else district_id
        result = await db.execute(select(School).where(School.district_id == did).limit(limit))
    else:
        result = await db.execute(select(School).limit(limit))
        
    return result.scalars().all()


@router.post("/", response_model=SchoolResponse, status_code=status.HTTP_201_CREATED)
async def create_school(
    school_in: SchoolCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Create new school (Admin only)."""
    if current_user.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Not authorized")
        
    school = School(**school_in.model_dump())
    db.add(school)
    await db.commit()
    await db.refresh(school)
    return school


@router.get("/{school_id}", response_model=SchoolResponse)
async def get_school(
    school_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Get school by ID."""
    result = await db.execute(select(School).where(School.id == school_id))
    school = result.scalars().first()
    if not school:
        raise HTTPException(status_code=404, detail="School not found")
    return school


@router.get("/{school_id}/inventory")
async def get_school_inventory(
    school_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Return the authenticated school's stock in the format used by the app."""
    if current_user.role in ["TEACHER", "PRINCIPAL"] and current_user.school_id != school_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    rows = await db.execute(
        select(Inventory, FoodItem)
        .join(FoodItem, Inventory.food_item_id == FoodItem.id)
        .where(Inventory.school_id == school_id)
    )
    return [
        {
            "id": str(inventory.id),
            "food_item_id": str(food_item.id),
            "item_name": food_item.name,
            "category": food_item.category.value if hasattr(food_item.category, "value") else str(food_item.category),
            "quantity": inventory.quantity,
            "unit": inventory.unit or food_item.unit,
            "minimum_quantity": inventory.minimum_quantity,
            "is_low_stock": inventory.quantity <= inventory.minimum_quantity,
            "last_updated": inventory.last_updated.isoformat() if inventory.last_updated else None,
        }
        for inventory, food_item in rows.all()
    ]


@router.get("/{school_id}/dashboard/teacher", response_model=TeacherDashboard)
async def get_teacher_dashboard(
    school_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Get dashboard data for a teacher."""
    # Verify auth
    if current_user.role == "TEACHER" and current_user.school_id != school_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    # Fetch school
    school_result = await db.execute(select(School).where(School.id == school_id))
    school = school_result.scalars().first()
    if not school:
        raise HTTPException(status_code=404, detail="School not found")

    # Fetch recent meals
    meals_result = await db.execute(
        select(Meal).where(Meal.school_id == school_id).order_by(Meal.created_at.desc()).limit(5)
    )
    recent_meals = meals_result.scalars().all()

    # Calculate metrics
    today = date.today()
    meals_today = sum(1 for m in recent_meals if m.meal_date == today)
    students_present = sum(m.students_present for m in recent_meals if m.meal_date == today)
    
    avg_compliance = 0.0
    if recent_meals:
        avg_compliance = sum(m.overall_score or 0 for m in recent_meals) / len(recent_meals)

    # Fetch waste
    waste_result = await db.execute(
        select(FoodWaste).where(FoodWaste.school_id == school_id).order_by(FoodWaste.created_at.desc()).limit(10)
    )
    waste_records = waste_result.scalars().all()
    total_waste = sum(w.quantity for w in waste_records)

    return TeacherDashboard(
        school=school,
        students_present=students_present,
        meals_served_today=meals_today,
        compliance_percent=round(avg_compliance, 1),
        food_waste_kg=round(total_waste, 1),
        recent_meals=recent_meals,
        alerts=[],
        waste_trend=[]
    )


@router.get("/{school_id}/dashboard/principal", response_model=PrincipalDashboard)
async def get_principal_dashboard(
    school_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Return the school-level information required by the principal view."""
    if current_user.role in ["TEACHER", "PRINCIPAL"] and current_user.school_id != school_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    school = (await db.execute(select(School).where(School.id == school_id))).scalars().first()
    if not school:
        raise HTTPException(status_code=404, detail="School not found")

    meals = (await db.execute(select(Meal).where(Meal.school_id == school_id).order_by(Meal.created_at.desc()).limit(20))).scalars().all()
    waste = (await db.execute(select(FoodWaste).where(FoodWaste.school_id == school_id))).scalars().all()
    inventory = (await db.execute(select(Inventory).where(Inventory.school_id == school_id))).scalars().all()
    recommendations = (await db.execute(select(Recommendation).where(Recommendation.school_id == school_id))).scalars().all()
    alerts = (await db.execute(select(Alert).where(Alert.school_id == school_id))).scalars().all()

    scored_meals = [m for m in meals if m.overall_score is not None]
    nutrition_meals = [m for m in meals if m.nutrition_score is not None]
    in_stock = sum(1 for item in inventory if item.quantity >= item.minimum_quantity)
    return PrincipalDashboard(
        school=school,
        total_students=school.student_count,
        attendance_today=sum(m.students_present for m in meals if m.meal_date == date.today()),
        meals_today=sum(1 for m in meals if m.meal_date == date.today()),
        compliance_score=round(sum(m.overall_score for m in scored_meals) / len(scored_meals), 1) if scored_meals else 0.0,
        nutrition_score=round(sum(m.nutrition_score for m in nutrition_meals) / len(nutrition_meals), 1) if nutrition_meals else 0.0,
        waste_kg=round(sum(w.quantity for w in waste), 1),
        inventory_health=round((in_stock / len(inventory)) * 100, 1) if inventory else 100.0,
        alerts=alerts,
        recommendations=recommendations,
        meal_history=meals,
    )
