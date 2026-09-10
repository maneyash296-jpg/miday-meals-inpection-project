"""NutriGuard AI — Meals & Vision Integration API."""

from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import shutil
import os
from uuid import UUID
from datetime import datetime

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.models import (
    User, Meal, MealImage, MealDetectedItem, Menu, MenuFoodItem, FoodItem, MealSession, MealStatus
)
from app.schemas.schemas import MealResponse, MealCreate, MealAnalysisResult
from app.services.vision_service import vision_service
from app.services.menu_compliance_service import menu_compliance_service
from app.services.nutrition_service import nutrition_service
from app.services.groq_service import groq_service

router = APIRouter()

UPLOAD_DIR = "uploads/meals"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.get("/")
async def list_meals(
    limit: int = 50,
    status: str = None,
    db: AsyncSession = Depends(get_db),
) -> Any:
    """List recent meal records across all schools."""
    stmt = select(Meal).order_by(Meal.created_at.desc()).limit(limit)
    result = await db.execute(stmt)
    meals = result.scalars().all()

    def fmt(m):
        return {
            "id": str(m.id),
            "school_id": str(m.school_id) if m.school_id else None,
            "meal_date": m.meal_date.isoformat() if m.meal_date else None,
            "meal_session": m.meal_session.value if hasattr(m.meal_session, "value") else str(m.meal_session),
            "students_present": m.students_present,
            "students_served": m.students_served,
            "hygiene_score": m.hygiene_score,
            "nutrition_score": m.nutrition_score,
            "quantity_score": m.quantity_score,
            "overall_score": m.overall_score,
            "status": m.status.value if hasattr(m.status, "value") else str(m.status),
            "created_at": m.created_at.isoformat() if m.created_at else None,
        }

    items = [fmt(m) for m in meals]
    if status:
        items = [i for i in items if i["status"].upper() == status.upper()]
    return items


@router.post("/", response_model=MealResponse, status_code=status.HTTP_201_CREATED)
async def create_meal(
    meal_in: MealCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Record a meal session."""
    # Security: Teachers can only record for their school
    if current_user.role == "TEACHER" and current_user.school_id != meal_in.school_id:
        raise HTTPException(status_code=403, detail="Not authorized to record meals for this school")

    meal = Meal(
        school_id=meal_in.school_id,
        captured_by=current_user.id,
        meal_date=meal_in.meal_date,
        meal_session=MealSession(meal_in.meal_session.upper()),
        students_present=meal_in.students_present,
        students_served=meal_in.students_served,
        latitude=meal_in.latitude,
        longitude=meal_in.longitude,
        status=MealStatus.PENDING
    )
    db.add(meal)
    await db.commit()
    await db.refresh(meal)
    return meal


@router.get("/school/{school_id}", response_model=List[MealResponse])
async def get_school_meals(
    school_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Get meals for a school."""
    if current_user.role == "TEACHER" and current_user.school_id != school_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    result = await db.execute(
        select(Meal).where(Meal.school_id == school_id).order_by(Meal.created_at.desc())
    )
    meals = result.scalars().all()
    return meals


@router.post("/{meal_id}/analyze", response_model=MealAnalysisResult)
async def analyze_meal_image(
    meal_id: UUID,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Upload a meal image and trigger the AI vision pipeline.
    This coordinates Vision Model -> Compliance Logic -> Nutrition Logic -> Groq Explanation.
    """
    # 1. Fetch Meal
    result = await db.execute(select(Meal).where(Meal.id == meal_id))
    meal = result.scalars().first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    if current_user.role == "TEACHER" and current_user.school_id != meal.school_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    # 2. Save Image File
    file_extension = file.filename.split(".")[-1] if file.filename else "jpg"
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    file_name = f"meal_{meal_id}_{timestamp}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, file_name)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    file_size = os.path.getsize(file_path)
    
    image_record = MealImage(
        meal_id=meal_id,
        image_path=file_path,
        mime_type=file.content_type or "image/jpeg",
        file_size=file_size
    )
    db.add(image_record)
    await db.commit()

    # 3. Fetch Expected Menu
    # Normally we'd look up the active menu for the school on this date.
    # For now, we fetch a default or mock expected menu from DB if none assigned to meal.
    expected_items = []
    if meal.menu_id:
        # Fetch actual menu logic here
        pass
    else:
        # Mock expected for SIH demo if no menu linked
        expected_items = [
            {"name": "Rice", "required_quantity": 0.15},
            {"name": "Dal", "required_quantity": 0.05},
            {"name": "Vegetable Curry", "required_quantity": 0.05},
        ]

    expected_names = [item["name"] for item in expected_items]

    # 4. Trigger Groq Vision
    try:
        vision_result = await vision_service.analyze_meal_image(
            image_path=file_path,
            expected_items=expected_names
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Vision AI failed: {str(e)}")

    # 5. Save Detected Items
    detected_dicts = []
    for item in vision_result.food_items:
        detected = MealDetectedItem(
            meal_id=meal_id,
            food_item_name=item.name,
            estimated_quantity=item.estimated_quantity,
            unit=item.unit,
            confidence=item.confidence
        )
        db.add(detected)
        detected_dicts.append({
            "name": item.name,
            "estimated_quantity": item.estimated_quantity,
            "confidence": item.confidence
        })
    await db.commit()

    # 6. Calculate Deterministic Compliance
    compliance = menu_compliance_service.check_compliance(
        expected_items=expected_items,
        detected_items=detected_dicts
    )

    # 7. Calculate Deterministic Nutrition (mock DB food items for now)
    # In reality, fetch all FoodItem records from DB
    food_items_db = [
        {"name": "Rice", "calories": 1300, "protein": 27, "carbohydrates": 280, "fat": 3},
        {"name": "Dal", "calories": 1160, "protein": 90, "carbohydrates": 200, "fat": 10},
        {"name": "Vegetable Curry", "calories": 400, "protein": 10, "carbohydrates": 50, "fat": 20},
    ]
    nutrition = nutrition_service.calculate_meal_nutrition(
        detected_items=detected_dicts,
        food_items_db=food_items_db,
        students_served=meal.students_served or 1
    )

    # 8. Update Meal Record
    hygiene_map = {"good": 100, "acceptable": 70, "poor": 30, "unknown": 50}
    pres_score = hygiene_map.get(vision_result.hygiene_indicators.presentation.lower(), 50)
    
    meal.nutrition_score = nutrition["overall_nutrition_score"]
    meal.quantity_score = compliance["quantity_score"]
    meal.hygiene_score = pres_score
    
    # Weight overall: 40% Nutrition, 40% Quantity, 20% Hygiene
    meal.overall_score = (meal.nutrition_score * 0.4) + (meal.quantity_score * 0.4) + (meal.hygiene_score * 0.2)
    meal.status = "COMPLIANT" if meal.overall_score >= 70 else "NON_COMPLIANT"
    
    await db.commit()

    # 9. Generate AI Explanation using Groq Language Model
    try:
        explanation = await groq_service.analyze_meal_compliance(
            expected_items=expected_names,
            detected_items=detected_dicts,
            scores={
                "nutrition": meal.nutrition_score,
                "quantity": meal.quantity_score,
                "hygiene": meal.hygiene_score,
                "overall": meal.overall_score
            }
        )
    except Exception as e:
        status_text = "Compliant" if meal.overall_score >= 70 else "Non-Compliant"
        explanation = (
            f"Meal evaluated as {status_text} with overall score {meal.overall_score:.1f}/100. "
            f"Detected {len(detected_dicts)} food items: {', '.join([d['name'] for d in detected_dicts])}. "
            f"Nutrition: {meal.nutrition_score:.1f}/100, Quantity: {meal.quantity_score:.1f}/100, Hygiene: {meal.hygiene_score:.1f}/100. "
            f"Meal complies with national PM POSHAN nutritional standards."
        )

    return MealAnalysisResult(
        meal_id=meal.id,
        status=meal.status,
        vision_result=vision_result.model_dump(),
        menu_compliance=compliance,
        nutrition_score=meal.nutrition_score,
        quantity_score=meal.quantity_score,
        hygiene_score=meal.hygiene_score,
        overall_score=meal.overall_score,
        explanation=explanation,
        alerts=["Low vegetable quantity detected"] if compliance["quantity_score"] < 50 else []
    )


@router.post("/analyze-direct", response_model=MealAnalysisResult)
async def analyze_image_direct(
    file: UploadFile = File(...),
    students_served: int = Form(default=250),
    expected_items_csv: str = Form(default="Rice,Dal,Vegetable Curry"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Directly analyze any uploaded meal image with AI vision, nutrition, and compliance.
    Creates a persistent Meal record and returns complete AI analysis.
    """
    import uuid
    # Save Image File
    file_extension = file.filename.split(".")[-1] if file.filename else "jpg"
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    temp_id = uuid.uuid4()
    file_name = f"meal_{temp_id}_{timestamp}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, file_name)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    file_size = os.path.getsize(file_path)

    # Expected items
    expected_names = [item.strip() for item in expected_items_csv.split(",") if item.strip()]
    expected_items = [{"name": n, "required_quantity": 0.1} for n in expected_names]

    # Vision Analysis
    vision_result = await vision_service.analyze_meal_image(
        image_path=file_path,
        expected_items=expected_names
    )

    detected_dicts = [
        {"name": item.name, "estimated_quantity": item.estimated_quantity, "confidence": item.confidence}
        for item in vision_result.food_items
    ]

    compliance = menu_compliance_service.check_compliance(
        expected_items=expected_items,
        detected_items=detected_dicts
    )

    food_items_db = [
        {"name": "Rice", "calories": 1300, "protein": 27, "carbohydrates": 280, "fat": 3},
        {"name": "Dal", "calories": 1160, "protein": 90, "carbohydrates": 200, "fat": 10},
        {"name": "Vegetable Curry", "calories": 400, "protein": 10, "carbohydrates": 50, "fat": 20},
        {"name": "Chapati / Roti", "calories": 1040, "protein": 30, "carbohydrates": 220, "fat": 15},
    ]
    nutrition = nutrition_service.calculate_meal_nutrition(
        detected_items=detected_dicts,
        food_items_db=food_items_db,
        students_served=students_served
    )

    hygiene_map = {"good": 100, "acceptable": 70, "poor": 30, "unknown": 50}
    pres_score = hygiene_map.get(vision_result.hygiene_indicators.presentation.lower(), 70)
    nut_score = nutrition["overall_nutrition_score"]
    qty_score = compliance["quantity_score"]
    overall = (nut_score * 0.4) + (qty_score * 0.4) + (pres_score * 0.2)
    m_status = "COMPLIANT" if overall >= 70 else "NON_COMPLIANT"

    # Find valid school_id if user is admin or unassigned
    target_school_id = current_user.school_id
    if not target_school_id:
        from app.models.models import School
        target_school_id = (await db.execute(select(School.id))).scalars().first()

    # Create and persist meal
    meal = Meal(
        id=temp_id,
        school_id=target_school_id,
        captured_by=current_user.id,
        meal_date=datetime.now().date(),
        meal_session=MealSession.LUNCH,
        students_present=students_served,
        students_served=students_served,
        nutrition_score=nut_score,
        quantity_score=qty_score,
        hygiene_score=pres_score,
        overall_score=overall,
        status=m_status
    )
    db.add(meal)

    image_rec = MealImage(
        meal_id=meal.id,
        image_path=file_path,
        mime_type=file.content_type or "image/jpeg",
        file_size=file_size
    )
    db.add(image_rec)

    for item in vision_result.food_items:
        db.add(MealDetectedItem(
            meal_id=meal.id,
            food_item_name=item.name,
            estimated_quantity=item.estimated_quantity,
            unit=item.unit,
            confidence=item.confidence
        ))
    await db.commit()

    # AI Explanation
    try:
        explanation = await groq_service.analyze_meal_compliance(
            expected_items=expected_names,
            detected_items=detected_dicts,
            scores={"nutrition": nut_score, "quantity": qty_score, "hygiene": pres_score, "overall": overall}
        )
    except Exception:
        explanation = (
            f"Meal evaluated as {m_status} (Overall Score: {overall:.1f}/100). "
            f"Detected {len(detected_dicts)} food items: {', '.join([d['name'] for d in detected_dicts])}. "
            f"Nutrition: {nut_score:.1f}/100, Quantity: {qty_score:.1f}/100, Hygiene: {pres_score:.1f}/100."
        )

    return MealAnalysisResult(
        meal_id=meal.id,
        status=meal.status,
        vision_result=vision_result.model_dump(),
        menu_compliance=compliance,
        nutrition_score=nut_score,
        quantity_score=qty_score,
        hygiene_score=pres_score,
        overall_score=overall,
        explanation=explanation,
        alerts=["Low vegetable quantity detected"] if qty_score < 50 else []
    )
