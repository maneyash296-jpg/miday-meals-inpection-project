"""NutriGuard AI — Pydantic v2 Schemas for all API contracts."""

from pydantic import BaseModel, Field, EmailStr, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime, date
from uuid import UUID
from enum import Enum


# ══════════════════════════════════════════════════════════════════════════════
# Shared / Base
# ══════════════════════════════════════════════════════════════════════════════

class SuccessResponse(BaseModel):
    success: bool = True
    message: str = "OK"


class ErrorDetail(BaseModel):
    code: str
    message: str


class ErrorResponse(BaseModel):
    success: bool = False
    error: ErrorDetail


class PaginatedResponse(BaseModel):
    items: List[Any] = []
    total: int = 0
    page: int = 1
    page_size: int = 20


# ══════════════════════════════════════════════════════════════════════════════
# Auth
# ══════════════════════════════════════════════════════════════════════════════

class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    email: str = Field(..., max_length=255)
    phone: Optional[str] = None
    password: str = Field(..., min_length=6)
    role: str = "TEACHER"
    district_id: Optional[UUID] = None
    school_id: Optional[UUID] = None
    ration_shop_id: Optional[UUID] = None


# ══════════════════════════════════════════════════════════════════════════════
# User
# ══════════════════════════════════════════════════════════════════════════════

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    email: str
    phone: Optional[str] = None
    role: str
    district_id: Optional[UUID] = None
    school_id: Optional[UUID] = None
    ration_shop_id: Optional[UUID] = None
    is_active: bool
    created_at: datetime


# ══════════════════════════════════════════════════════════════════════════════
# District
# ══════════════════════════════════════════════════════════════════════════════

class DistrictResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    code: str
    state: str
    created_at: datetime


# ══════════════════════════════════════════════════════════════════════════════
# School
# ══════════════════════════════════════════════════════════════════════════════

class SchoolCreate(BaseModel):
    name: str = Field(..., min_length=3)
    school_code: str = Field(..., min_length=3)
    district_id: UUID
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    student_count: int = 0


class SchoolResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    school_code: str
    district_id: UUID
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    student_count: int
    active: bool
    created_at: datetime


class SchoolDashboard(BaseModel):
    school: SchoolResponse
    students_count: int = 0
    meals_today: int = 0
    compliance_score: float = 0.0
    total_waste_kg: float = 0.0
    inventory_items: int = 0
    low_stock_items: int = 0
    active_alerts: int = 0
    recent_meals: List[Any] = []
    recent_alerts: List[Any] = []
    recommendations: List[Any] = []
    waste_trend: List[Dict[str, Any]] = []
    nutrition_summary: Dict[str, Any] = {}


# ══════════════════════════════════════════════════════════════════════════════
# Food Item
# ══════════════════════════════════════════════════════════════════════════════

class FoodItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    category: str
    unit: str
    calories: float
    protein: float
    carbohydrates: float
    fat: float
    storage_days: int
    minimum_stock_level: float


# ══════════════════════════════════════════════════════════════════════════════
# Menu
# ══════════════════════════════════════════════════════════════════════════════

class MenuFoodItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    food_item_id: UUID
    food_item: Optional[FoodItemResponse] = None
    required_quantity: float
    required_unit: str
    minimum_quantity: float


class MenuResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    menu_date: date
    meal_session: str
    title: str
    nutrition_target: Optional[Dict[str, Any]] = None
    active: bool
    food_items: List[MenuFoodItemResponse] = []


# ══════════════════════════════════════════════════════════════════════════════
# Meal
# ══════════════════════════════════════════════════════════════════════════════

class MealCreate(BaseModel):
    school_id: UUID
    meal_date: date
    meal_session: str = "LUNCH"
    students_present: int = 0
    students_served: int = 0
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class MealImageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    meal_id: UUID
    image_url: Optional[str] = None
    image_path: str
    mime_type: str
    file_size: int
    created_at: datetime


class MealFoodItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    food_item_name: str
    food_item_id: Optional[UUID] = None
    estimated_quantity: float
    unit: str
    confidence: float


class MealResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    school_id: UUID
    menu_id: Optional[UUID] = None
    captured_by: UUID
    meal_date: date
    meal_session: str
    students_present: int
    students_served: int
    status: str
    nutrition_score: Optional[float] = None
    quantity_score: Optional[float] = None
    hygiene_score: Optional[float] = None
    overall_score: Optional[float] = None
    images: List[MealImageResponse] = []
    detected_items: List[MealFoodItemResponse] = []
    created_at: datetime


# ══════════════════════════════════════════════════════════════════════════════
# Inventory
# ══════════════════════════════════════════════════════════════════════════════

class InventoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    school_id: Optional[UUID] = None
    ration_shop_id: Optional[UUID] = None
    food_item_id: UUID
    food_item: Optional[FoodItemResponse] = None
    quantity: float
    unit: str
    minimum_quantity: float
    last_updated: datetime


class InventoryReceive(BaseModel):
    food_item_id: UUID
    quantity: float = Field(..., gt=0)
    notes: Optional[str] = None


class InventoryAdjust(BaseModel):
    food_item_id: UUID
    new_quantity: float = Field(..., ge=0)
    reason: str


class InventoryTransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    inventory_id: UUID
    transaction_type: str
    quantity: float
    reference_type: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime


# ══════════════════════════════════════════════════════════════════════════════
# Ration Shop
# ══════════════════════════════════════════════════════════════════════════════

class RationShopResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    shop_code: str
    name: str
    district_id: UUID
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    capacity: Optional[float] = None
    current_risk_score: float
    active: bool
    created_at: datetime


class RationShopDashboard(BaseModel):
    shop: RationShopResponse
    total_stock_items: int = 0
    low_stock_count: int = 0
    pending_allocations: int = 0
    pending_deliveries: int = 0
    schools_served: int = 0
    risk_score: float = 0.0
    inventory: List[InventoryResponse] = []
    recent_deliveries: List[Any] = []
    alerts: List[Any] = []
    recommendations: List[Any] = []


# ══════════════════════════════════════════════════════════════════════════════
# Allocation
# ══════════════════════════════════════════════════════════════════════════════

class AllocationCreate(BaseModel):
    school_id: UUID
    food_item_id: UUID
    allocated_quantity: float = Field(..., gt=0)
    recommended_quantity: Optional[float] = None
    allocation_date: date


class AllocationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    ration_shop_id: UUID
    school_id: UUID
    food_item_id: UUID
    food_item: Optional[FoodItemResponse] = None
    allocated_quantity: float
    recommended_quantity: Optional[float] = None
    allocation_date: date
    status: str
    created_at: datetime


# ══════════════════════════════════════════════════════════════════════════════
# Delivery
# ══════════════════════════════════════════════════════════════════════════════

class DeliveryItemCreate(BaseModel):
    food_item_id: UUID
    expected_quantity: float
    dispatched_quantity: float


class DeliveryCreate(BaseModel):
    school_id: UUID
    vehicle_number: Optional[str] = None
    driver_name: Optional[str] = None
    expected_delivery: Optional[datetime] = None
    items: List[DeliveryItemCreate] = []


class DeliveryItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    food_item_id: UUID
    food_item: Optional[FoodItemResponse] = None
    expected_quantity: float
    dispatched_quantity: float
    received_quantity: Optional[float] = None
    difference_quantity: Optional[float] = None


class DeliveryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    ration_shop_id: UUID
    school_id: UUID
    delivery_number: str
    vehicle_number: Optional[str] = None
    driver_name: Optional[str] = None
    status: str
    dispatch_time: Optional[datetime] = None
    received_time: Optional[datetime] = None
    items: List[DeliveryItemResponse] = []
    created_at: datetime


class DeliveryReceive(BaseModel):
    items: List[Dict[str, float]]  # [{"food_item_id": ..., "received_quantity": ...}]


# ══════════════════════════════════════════════════════════════════════════════
# Waste
# ══════════════════════════════════════════════════════════════════════════════

class WasteCreate(BaseModel):
    school_id: UUID
    food_item_id: Optional[UUID] = None
    meal_id: Optional[UUID] = None
    quantity: float = Field(..., gt=0)
    unit: str = "kg"
    reason: str
    waste_date: date


class WasteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    school_id: UUID
    food_item_id: Optional[UUID] = None
    food_item: Optional[FoodItemResponse] = None
    meal_id: Optional[UUID] = None
    quantity: float
    unit: str
    reason: str
    waste_date: date
    created_at: datetime


# ══════════════════════════════════════════════════════════════════════════════
# Prediction
# ══════════════════════════════════════════════════════════════════════════════

class PredictionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    school_id: Optional[UUID] = None
    ration_shop_id: Optional[UUID] = None
    prediction_type: str
    target_date: date
    predicted_value: float
    confidence: float
    risk_level: str
    model_version: str
    features_json: Optional[Dict[str, Any]] = None
    created_at: datetime


# ══════════════════════════════════════════════════════════════════════════════
# Recommendation
# ══════════════════════════════════════════════════════════════════════════════

class RecommendationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    school_id: Optional[UUID] = None
    ration_shop_id: Optional[UUID] = None
    recommendation_type: str
    priority: str
    title: str
    description: str
    evidence_json: Optional[Dict[str, Any]] = None
    expected_impact: Optional[str] = None
    status: str
    created_at: datetime
    reviewed_by: Optional[UUID] = None
    reviewed_at: Optional[datetime] = None


class RecommendationAction(BaseModel):
    notes: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
# Alert
# ══════════════════════════════════════════════════════════════════════════════

class AlertResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    school_id: Optional[UUID] = None
    ration_shop_id: Optional[UUID] = None
    alert_type: str
    severity: str
    title: str
    message: str
    source: str
    status: str
    created_at: datetime
    resolved_at: Optional[datetime] = None


# ══════════════════════════════════════════════════════════════════════════════
# Dashboard
# ══════════════════════════════════════════════════════════════════════════════

class TeacherDashboard(BaseModel):
    school: Optional[SchoolResponse] = None
    students_present: int = 0
    meals_served_today: int = 0
    compliance_percent: float = 0.0
    food_waste_kg: float = 0.0
    recent_meals: List[MealResponse] = []
    alerts: List[AlertResponse] = []
    waste_trend: List[Dict[str, Any]] = []


class PrincipalDashboard(BaseModel):
    school: Optional[SchoolResponse] = None
    total_students: int = 0
    attendance_today: int = 0
    meals_today: int = 0
    compliance_score: float = 0.0
    nutrition_score: float = 0.0
    waste_kg: float = 0.0
    inventory_health: float = 0.0
    alerts: List[AlertResponse] = []
    recommendations: List[RecommendationResponse] = []
    waste_trend: List[Dict[str, Any]] = []
    meal_history: List[MealResponse] = []


class DistrictDashboard(BaseModel):
    district: Optional[DistrictResponse] = None
    total_schools: int = 0
    total_ration_shops: int = 0
    total_students: int = 0
    meals_monitored_today: int = 0
    avg_compliance: float = 0.0
    total_waste_kg: float = 0.0
    resource_savings: float = 0.0
    high_risk_schools: List[Dict[str, Any]] = []
    high_risk_ration_shops: List[Dict[str, Any]] = []
    alerts: List[AlertResponse] = []
    school_coordinates: List[Dict[str, Any]] = []
    waste_trend: List[Dict[str, Any]] = []
    compliance_trend: List[Dict[str, Any]] = []


class AdminDashboard(BaseModel):
    total_districts: int = 0
    total_schools: int = 0
    total_ration_shops: int = 0
    total_users: int = 0
    total_students: int = 0
    total_meals: int = 0
    avg_compliance: float = 0.0
    total_waste_kg: float = 0.0
    total_resource_savings: float = 0.0
    active_alerts: int = 0
    pending_recommendations: int = 0
    recent_audit_logs: List[Dict[str, Any]] = []
    system_health: Dict[str, Any] = {}


# ══════════════════════════════════════════════════════════════════════════════
# AI Analysis
# ══════════════════════════════════════════════════════════════════════════════

class VisionAnalysisResult(BaseModel):
    food_items: List[Dict[str, Any]] = []
    missing_items: List[str] = []
    hygiene_indicators: Dict[str, str] = {}
    confidence: float = 0.0


class MealAnalysisResult(BaseModel):
    meal_id: UUID
    status: str
    vision_result: Optional[VisionAnalysisResult] = None
    menu_compliance: Dict[str, Any] = {}
    nutrition_score: float = 0.0
    quantity_score: float = 0.0
    hygiene_score: float = 0.0
    overall_score: float = 0.0
    explanation: str = ""
    recommendation: Optional[str] = None
    alerts: List[str] = []


# ══════════════════════════════════════════════════════════════════════════════
# Supply Chain
# ══════════════════════════════════════════════════════════════════════════════

class SupplyChainResponse(BaseModel):
    ration_shop: Optional[RationShopResponse] = None
    school: Optional[SchoolResponse] = None
    allocations: List[AllocationResponse] = []
    deliveries: List[DeliveryResponse] = []
    inventory_at_shop: List[InventoryResponse] = []
    inventory_at_school: List[InventoryResponse] = []


# ══════════════════════════════════════════════════════════════════════════════
# Report
# ══════════════════════════════════════════════════════════════════════════════

class ReportRequest(BaseModel):
    report_type: str
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    school_id: Optional[UUID] = None
    district_id: Optional[UUID] = None
    ration_shop_id: Optional[UUID] = None


class ReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    report_type: str
    title: str
    status: str
    file_path: Optional[str] = None
    created_at: datetime
