"""NutriGuard AI — Main API Router."""

from fastapi import APIRouter

from app.api.endpoints import auth, schools, meals, ai_insights, search, alerts, ration_shops, districts, recommendations

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(schools.router, prefix="/schools", tags=["schools"])
api_router.include_router(meals.router, prefix="/meals", tags=["meals"])
api_router.include_router(ai_insights.router, prefix="/ai", tags=["ai-insights"])
api_router.include_router(search.router, prefix="/search", tags=["search"])
api_router.include_router(alerts.router, prefix="/alerts", tags=["alerts"])
api_router.include_router(ration_shops.router, prefix="/ration-shops", tags=["ration-shops"])
api_router.include_router(districts.router, prefix="/districts", tags=["districts"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["recommendations"])
