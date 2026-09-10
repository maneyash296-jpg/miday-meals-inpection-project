"""NutriGuard AI — AI Insights, Waste ML Prediction & Model Management API."""

from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, Field
from uuid import UUID
import json
import os

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.models import User, Prediction
from app.services.groq_service import groq_service
from app.services.waste_prediction_service import waste_prediction_service
from app.ml.train_model import train_waste_model, META_PATH

router = APIRouter()


class PredictWasteRequest(BaseModel):
    historical_waste: List[float] = Field(default=[18.5, 16.2, 19.0, 15.5, 21.0, 17.8, 19.5])
    student_counts: List[int] = Field(default=[280, 290, 275, 285, 295, 280, 290])
    meals_served: List[int] = Field(default=[280, 290, 275, 285, 295, 280, 290])
    school_size: int = 300
    days_ahead: int = 7
    temperature_c: float = 28.5
    menu_category_id: int = 0
    portion_size_g: float = 250.0


@router.post("/predict-waste")
async def predict_waste(
    request: PredictWasteRequest,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Predict food waste using NutriGuard trained Gradient Boosting ML Model."""
    prediction = waste_prediction_service.predict_waste(
        historical_waste=request.historical_waste,
        student_counts=request.student_counts,
        meals_served=request.meals_served,
        school_size=request.school_size,
        days_ahead=request.days_ahead,
        temperature_c=request.temperature_c,
        menu_category_id=request.menu_category_id,
        portion_size_g=request.portion_size_g,
    )
    return prediction


@router.get("/model-metrics")
async def get_model_metrics(
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Retrieve accuracy metrics ($R^2$, RMSE, MAE, feature importances) of the trained ML model."""
    if os.path.exists(META_PATH):
        with open(META_PATH, "r") as f:
            meta = json.load(f)
        return {"status": "success", "metrics": meta}
    return {
        "status": "not_trained",
        "message": "No pre-trained ML model metadata found. Call POST /ai/train-model to train.",
    }


@router.post("/train-model")
async def trigger_model_training(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Train or re-train the food waste prediction ML model."""
    if current_user.role not in ["ADMIN", "DISTRICT_OFFICER"]:
        raise HTTPException(status_code=403, detail="Only administrators can trigger ML model retraining")

    # Run training in background task
    def _run_train():
        meta = train_waste_model()
        waste_prediction_service._load_model()
        return meta

    background_tasks.add_task(_run_train)
    return {
        "status": "processing",
        "message": "ML model training initiated in background. Check GET /ai/model-metrics for status.",
    }


@router.post("/prediction/{prediction_id}/explain")
async def explain_prediction(
    prediction_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Generate a human-readable explanation of an ML prediction using Groq."""
    result = await db.execute(select(Prediction).where(Prediction.id == prediction_id))
    pred = result.scalars().first()
    if not pred:
        raise HTTPException(status_code=404, detail="Prediction not found")

    explanation = await groq_service.explain_prediction(
        prediction_type=pred.prediction_type,
        predicted_value=pred.predicted_value,
        confidence=pred.confidence,
        risk_level=pred.risk_level,
        features=pred.features_json or {},
        context=f"Target Date: {pred.target_date}"
    )
    
    return {"explanation": explanation}


@router.post("/recommendation/generate")
async def generate_recommendation(
    evidence: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Generate a new AI recommendation based on provided evidence data."""
    if current_user.role not in ["ADMIN", "DISTRICT_OFFICER", "PRINCIPAL"]:
        raise HTTPException(status_code=403, detail="Not authorized")

    rec_json = await groq_service.generate_recommendation(
        evidence=evidence,
        context="Generating for school administrative review."
    )
    
    return {"recommendation_draft": rec_json}


@router.post("/dashboard/summarize")
async def summarize_dashboard(
    dashboard_data: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Summarize dashboard data into natural language."""
    summary = await groq_service.summarize_dashboard(
        dashboard_data=dashboard_data,
        role=current_user.role.lower()
    )
    
    return {"summary": summary}
