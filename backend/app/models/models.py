"""NutriGuard AI — All SQLAlchemy ORM models.

Single-file model registry for clarity.  Each class maps 1-to-1 to a
PostgreSQL table and uses UUID primary keys, UTC timestamps, and proper
foreign-key / index / check constraints.
"""

import uuid
from datetime import datetime, timezone
from typing import Optional, List

from sqlalchemy import (
    String, Text, Integer, Float, Boolean, DateTime, Date,
    ForeignKey, CheckConstraint, UniqueConstraint, Index, Enum as SAEnum,
    JSON,
)
from sqlalchemy.types import TypeDecorator, CHAR
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

import enum


class GUID(TypeDecorator):
    """Platform-independent GUID type. Uses PostgreSQL UUID type, otherwise CHAR(36)."""
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(PG_UUID(as_uuid=True))
        else:
            return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        if isinstance(value, uuid.UUID):
            return value
        try:
            return uuid.UUID(str(value))
        except (ValueError, TypeError):
            return value


# ══════════════════════════════════════════════════════════════════════════════
# Enumerations
# ══════════════════════════════════════════════════════════════════════════════

class UserRole(str, enum.Enum):
    TEACHER = "TEACHER"
    PRINCIPAL = "PRINCIPAL"
    RATION_SHOP = "RATION_SHOP"
    DISTRICT_OFFICER = "DISTRICT_OFFICER"
    ADMIN = "ADMIN"


class MealSession(str, enum.Enum):
    MORNING = "MORNING"
    LUNCH = "LUNCH"
    EVENING = "EVENING"


class MealStatus(str, enum.Enum):
    PENDING = "PENDING"
    ANALYZING = "ANALYZING"
    VERIFIED = "VERIFIED"
    NEEDS_REVIEW = "NEEDS_REVIEW"
    FAILED = "FAILED"
    COMPLIANT = "COMPLIANT"
    NON_COMPLIANT = "NON_COMPLIANT"


class TransactionType(str, enum.Enum):
    RECEIVED = "RECEIVED"
    DISPATCHED = "DISPATCHED"
    CONSUMED = "CONSUMED"
    WASTED = "WASTED"
    ADJUSTED = "ADJUSTED"
    TRANSFERRED = "TRANSFERRED"


class DeliveryStatus(str, enum.Enum):
    PENDING = "PENDING"
    DISPATCHED = "DISPATCHED"
    IN_TRANSIT = "IN_TRANSIT"
    DELIVERED = "DELIVERED"
    PARTIALLY_DELIVERED = "PARTIALLY_DELIVERED"
    REJECTED = "REJECTED"


class AllocationStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    DISPATCHED = "DISPATCHED"
    DELIVERED = "DELIVERED"
    REJECTED = "REJECTED"


class WasteReason(str, enum.Enum):
    PREPARATION_SURPLUS = "PREPARATION_SURPLUS"
    LEFTOVER = "LEFTOVER"
    SPOILED = "SPOILED"
    DAMAGED = "DAMAGED"
    EXPIRED = "EXPIRED"
    OTHER = "OTHER"


class PredictionType(str, enum.Enum):
    WASTE = "WASTE"
    SHORTAGE = "SHORTAGE"
    NUTRITION_RISK = "NUTRITION_RISK"
    SCHOOL_RISK = "SCHOOL_RISK"
    RATION_SHOP_RISK = "RATION_SHOP_RISK"


class RecommendationStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    MODIFIED = "MODIFIED"
    COMPLETED = "COMPLETED"


class AlertSeverity(str, enum.Enum):
    INFO = "INFO"
    WARNING = "WARNING"
    CRITICAL = "CRITICAL"


class AlertStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    ACKNOWLEDGED = "ACKNOWLEDGED"
    RESOLVED = "RESOLVED"


class RiskLevel(str, enum.Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class FoodCategory(str, enum.Enum):
    GRAIN = "GRAIN"
    PULSE = "PULSE"
    OIL = "OIL"
    VEGETABLE = "VEGETABLE"
    EGG = "EGG"
    FRUIT = "FRUIT"
    MILK = "MILK"
    SPICE = "SPICE"
    OTHER = "OTHER"


# ══════════════════════════════════════════════════════════════════════════════
# Helper mixin
# ══════════════════════════════════════════════════════════════════════════════

def _utcnow():
    return datetime.now(timezone.utc)


def _uuid():
    return uuid.uuid4()


# ══════════════════════════════════════════════════════════════════════════════
# Tables
# ══════════════════════════════════════════════════════════════════════════════

class District(Base):
    __tablename__ = "districts"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    code: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    state: Mapped[str] = mapped_column(String(100), nullable=False, default="Andhra Pradesh")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    # Relationships
    schools: Mapped[List["School"]] = relationship(back_populates="district", lazy="selectin")
    ration_shops: Mapped[List["RationShop"]] = relationship(back_populates="district", lazy="selectin")
    users: Mapped[List["User"]] = relationship(back_populates="district", lazy="selectin")


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(SAEnum(UserRole, name="user_role_enum"), nullable=False)
    district_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("districts.id"), nullable=True)
    school_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=True)
    ration_shop_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("ration_shops.id"), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    district: Mapped[Optional["District"]] = relationship(back_populates="users", lazy="selectin")

    __table_args__ = (
        Index("ix_users_role", "role"),
    )


class School(Base):
    __tablename__ = "schools"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(300), nullable=False)
    school_code: Mapped[str] = mapped_column(String(30), unique=True, nullable=False)
    district_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("districts.id"), nullable=False)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    student_count: Mapped[int] = mapped_column(Integer, default=0)
    principal_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    district: Mapped["District"] = relationship(back_populates="schools", lazy="selectin")
    meals: Mapped[List["MealRecord"]] = relationship(back_populates="school", lazy="selectin")
    waste_records: Mapped[List["WasteRecord"]] = relationship(back_populates="school", lazy="selectin")


class Student(Base):
    __tablename__ = "students"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    roll_number: Mapped[str] = mapped_column(String(30), nullable=False)
    school_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=False)
    grade: Mapped[str] = mapped_column(String(10), nullable=False)
    section: Mapped[Optional[str]] = mapped_column(String(5), nullable=True)
    gender: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    date_of_birth: Mapped[Optional[datetime]] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    __table_args__ = (
        UniqueConstraint("school_id", "roll_number", name="uq_student_roll"),
        Index("ix_students_school", "school_id"),
    )


class RationShop(Base):
    __tablename__ = "ration_shops"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    shop_code: Mapped[str] = mapped_column(String(30), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(300), nullable=False)
    district_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("districts.id"), nullable=False)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    manager_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), nullable=True)
    capacity: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    current_risk_score: Mapped[float] = mapped_column(Float, default=0.0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    district: Mapped["District"] = relationship(back_populates="ration_shops", lazy="selectin")


class FoodItem(Base):
    __tablename__ = "food_items"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(200), nullable=False, unique=True)
    category: Mapped[FoodCategory] = mapped_column(SAEnum(FoodCategory, name="food_category_enum"), nullable=False)
    unit: Mapped[str] = mapped_column(String(20), nullable=False, default="kg")
    calories: Mapped[float] = mapped_column(Float, default=0.0)
    protein: Mapped[float] = mapped_column(Float, default=0.0)
    carbohydrates: Mapped[float] = mapped_column(Float, default=0.0)
    fat: Mapped[float] = mapped_column(Float, default=0.0)
    storage_days: Mapped[int] = mapped_column(Integer, default=30)
    minimum_stock_level: Mapped[float] = mapped_column(Float, default=10.0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)


class Menu(Base):
    __tablename__ = "menus"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    menu_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    meal_session: Mapped[MealSession] = mapped_column(SAEnum(MealSession, name="meal_session_enum"), nullable=False)
    title: Mapped[str] = mapped_column(String(300), nullable=False)
    nutrition_target: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    food_items: Mapped[List["MenuFoodItem"]] = relationship(back_populates="menu", lazy="selectin")

    __table_args__ = (
        UniqueConstraint("menu_date", "meal_session", name="uq_menu_date_session"),
        Index("ix_menus_date", "menu_date"),
    )


class MenuFoodItem(Base):
    __tablename__ = "menu_food_items"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    menu_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("menus.id", ondelete="CASCADE"), nullable=False)
    food_item_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("food_items.id"), nullable=False)
    required_quantity: Mapped[float] = mapped_column(Float, nullable=False)
    required_unit: Mapped[str] = mapped_column(String(20), nullable=False, default="kg")
    minimum_quantity: Mapped[float] = mapped_column(Float, default=0.0)

    menu: Mapped["Menu"] = relationship(back_populates="food_items", lazy="selectin")
    food_item: Mapped["FoodItem"] = relationship(lazy="selectin")


class MealRecord(Base):
    __tablename__ = "meal_records"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    school_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=False)
    menu_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("menus.id"), nullable=True)
    captured_by: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("users.id"), nullable=False)
    meal_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    meal_session: Mapped[MealSession] = mapped_column(SAEnum(MealSession, name="meal_session_enum", create_constraint=False), nullable=False)
    students_present: Mapped[int] = mapped_column(Integer, default=0)
    students_served: Mapped[int] = mapped_column(Integer, default=0)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    capture_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[MealStatus] = mapped_column(SAEnum(MealStatus, name="meal_status_enum"), default=MealStatus.PENDING)
    nutrition_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    quantity_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    hygiene_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    overall_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    school: Mapped["School"] = relationship(back_populates="meals", lazy="selectin")
    images: Mapped[List["MealImage"]] = relationship(back_populates="meal", lazy="selectin")
    detected_items: Mapped[List["MealFoodItem"]] = relationship(back_populates="meal", lazy="selectin")

    __table_args__ = (
        Index("ix_meals_school_date", "school_id", "meal_date"),
        Index("ix_meals_status", "status"),
    )


class MealImage(Base):
    __tablename__ = "meal_images"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    meal_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("meal_records.id", ondelete="CASCADE"), nullable=False)
    image_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    image_path: Mapped[str] = mapped_column(String(500), nullable=False)
    mime_type: Mapped[str] = mapped_column(String(50), nullable=False, default="image/jpeg")
    file_size: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    meal: Mapped["MealRecord"] = relationship(back_populates="images", lazy="selectin")


class MealFoodItem(Base):
    __tablename__ = "meal_food_items"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    meal_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("meal_records.id", ondelete="CASCADE"), nullable=False)
    food_item_name: Mapped[str] = mapped_column(String(200), nullable=False)
    food_item_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("food_items.id"), nullable=True)
    estimated_quantity: Mapped[float] = mapped_column(Float, default=0.0)
    unit: Mapped[str] = mapped_column(String(20), default="kg")
    confidence: Mapped[float] = mapped_column(Float, default=0.0)

    meal: Mapped["MealRecord"] = relationship(back_populates="detected_items", lazy="selectin")


class Inventory(Base):
    __tablename__ = "inventory"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    school_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=True)
    ration_shop_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("ration_shops.id"), nullable=True)
    food_item_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("food_items.id"), nullable=False)
    quantity: Mapped[float] = mapped_column(Float, default=0.0)
    unit: Mapped[str] = mapped_column(String(20), default="kg")
    minimum_quantity: Mapped[float] = mapped_column(Float, default=10.0)
    last_updated: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    food_item: Mapped["FoodItem"] = relationship(lazy="selectin")

    __table_args__ = (
        CheckConstraint("(school_id IS NOT NULL) OR (ration_shop_id IS NOT NULL)", name="ck_inventory_owner"),
        Index("ix_inventory_school", "school_id"),
        Index("ix_inventory_ration_shop", "ration_shop_id"),
    )


class InventoryTransaction(Base):
    __tablename__ = "inventory_transactions"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    inventory_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("inventory.id"), nullable=False)
    transaction_type: Mapped[TransactionType] = mapped_column(SAEnum(TransactionType, name="transaction_type_enum"), nullable=False)
    quantity: Mapped[float] = mapped_column(Float, nullable=False)
    reference_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), nullable=True)
    reference_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    performed_by: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("users.id"), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    __table_args__ = (
        Index("ix_inv_txn_inventory", "inventory_id"),
        Index("ix_inv_txn_created", "created_at"),
    )


class RationAllocation(Base):
    __tablename__ = "ration_allocations"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    ration_shop_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("ration_shops.id"), nullable=False)
    school_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=False)
    food_item_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("food_items.id"), nullable=False)
    allocated_quantity: Mapped[float] = mapped_column(Float, nullable=False)
    recommended_quantity: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    allocation_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    approved_by: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("users.id"), nullable=True)
    status: Mapped[AllocationStatus] = mapped_column(SAEnum(AllocationStatus, name="allocation_status_enum"), default=AllocationStatus.PENDING)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    food_item: Mapped["FoodItem"] = relationship(lazy="selectin")


class RationDelivery(Base):
    __tablename__ = "ration_deliveries"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    ration_shop_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("ration_shops.id"), nullable=False)
    school_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=False)
    delivery_number: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    vehicle_number: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    driver_name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    expected_delivery: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    dispatch_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    received_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[DeliveryStatus] = mapped_column(SAEnum(DeliveryStatus, name="delivery_status_enum"), default=DeliveryStatus.PENDING)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    items: Mapped[List["DeliveryItem"]] = relationship(back_populates="delivery", lazy="selectin")

    __table_args__ = (
        Index("ix_delivery_school", "school_id"),
        Index("ix_delivery_ration", "ration_shop_id"),
    )


class DeliveryItem(Base):
    __tablename__ = "delivery_items"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    delivery_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("ration_deliveries.id", ondelete="CASCADE"), nullable=False)
    food_item_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("food_items.id"), nullable=False)
    expected_quantity: Mapped[float] = mapped_column(Float, default=0.0)
    dispatched_quantity: Mapped[float] = mapped_column(Float, default=0.0)
    received_quantity: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    difference_quantity: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    delivery: Mapped["RationDelivery"] = relationship(back_populates="items", lazy="selectin")
    food_item: Mapped["FoodItem"] = relationship(lazy="selectin")


class WasteRecord(Base):
    __tablename__ = "waste_records"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    school_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=False)
    food_item_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("food_items.id"), nullable=True)
    meal_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("meal_records.id"), nullable=True)
    quantity: Mapped[float] = mapped_column(Float, nullable=False)
    unit: Mapped[str] = mapped_column(String(20), default="kg")
    reason: Mapped[WasteReason] = mapped_column(SAEnum(WasteReason, name="waste_reason_enum"), nullable=False)
    recorded_by: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("users.id"), nullable=False)
    waste_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    school: Mapped["School"] = relationship(back_populates="waste_records", lazy="selectin")
    food_item: Mapped[Optional["FoodItem"]] = relationship(lazy="selectin")

    __table_args__ = (
        Index("ix_waste_school_date", "school_id", "waste_date"),
    )


class AIAnalysisLog(Base):
    __tablename__ = "ai_analysis_logs"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    meal_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("meal_records.id"), nullable=True)
    provider: Mapped[str] = mapped_column(String(50), nullable=False, default="groq")
    model: Mapped[str] = mapped_column(String(100), nullable=False)
    operation: Mapped[str] = mapped_column(String(100), nullable=False)
    prompt_version: Mapped[str] = mapped_column(String(20), default="1.0")
    input_reference: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    response_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    confidence: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="SUCCESS")
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)


class Prediction(Base):
    __tablename__ = "predictions"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    school_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=True)
    ration_shop_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("ration_shops.id"), nullable=True)
    prediction_type: Mapped[PredictionType] = mapped_column(SAEnum(PredictionType, name="prediction_type_enum"), nullable=False)
    target_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    predicted_value: Mapped[float] = mapped_column(Float, nullable=False)
    confidence: Mapped[float] = mapped_column(Float, default=0.0)
    risk_level: Mapped[RiskLevel] = mapped_column(SAEnum(RiskLevel, name="risk_level_enum"), default=RiskLevel.LOW)
    model_version: Mapped[str] = mapped_column(String(50), default="v1.0")
    features_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    __table_args__ = (
        Index("ix_pred_school", "school_id"),
        Index("ix_pred_type", "prediction_type"),
    )


class Recommendation(Base):
    __tablename__ = "recommendations"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    school_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=True)
    ration_shop_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("ration_shops.id"), nullable=True)
    recommendation_type: Mapped[str] = mapped_column(String(50), nullable=False)
    priority: Mapped[str] = mapped_column(String(20), nullable=False, default="MEDIUM")
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    evidence_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    expected_impact: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status: Mapped[RecommendationStatus] = mapped_column(SAEnum(RecommendationStatus, name="recommendation_status_enum"), default=RecommendationStatus.PENDING)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    reviewed_by: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("users.id"), nullable=True)
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("ix_rec_school", "school_id"),
        Index("ix_rec_status", "status"),
    )


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    school_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("schools.id"), nullable=True)
    ration_shop_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("ration_shops.id"), nullable=True)
    alert_type: Mapped[str] = mapped_column(String(50), nullable=False)
    severity: Mapped[AlertSeverity] = mapped_column(SAEnum(AlertSeverity, name="alert_severity_enum"), nullable=False)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    source: Mapped[str] = mapped_column(String(100), default="system")
    status: Mapped[AlertStatus] = mapped_column(SAEnum(AlertStatus, name="alert_status_enum"), default=AlertStatus.ACTIVE)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("ix_alert_school", "school_id"),
        Index("ix_alert_severity", "severity"),
    )


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    report_type: Mapped[str] = mapped_column(String(50), nullable=False)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    parameters: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    file_path: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    generated_by: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("users.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="GENERATING")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), ForeignKey("users.id"), nullable=True)
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(50), nullable=False)
    entity_id: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    details: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    ip_address: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    __table_args__ = (
        Index("ix_audit_user", "user_id"),
        Index("ix_audit_action", "action"),
        Index("ix_audit_created", "created_at"),
    )


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("users.id"), nullable=False)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    notification_type: Mapped[str] = mapped_column(String(50), default="INFO")
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    reference_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    reference_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    __table_args__ = (
        Index("ix_notif_user", "user_id"),
        Index("ix_notif_unread", "user_id", "is_read"),
    )


# Model Aliases for endpoint compatibility
Meal = MealRecord
FoodWaste = WasteRecord
MealDetectedItem = MealFoodItem

