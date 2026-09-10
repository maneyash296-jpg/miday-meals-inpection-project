"""NutriGuard AI — Database Seeding Script.

Populates initial PM POSHAN scheme dataset: Districts, Schools, Users, Ration Shops,
Food Items, Meal Records, Inventories, Waste Records, AI Predictions, and Alerts.
"""

import asyncio
import uuid
from datetime import datetime, timedelta, date, timezone
from sqlalchemy import select

from app.core.database import async_session, init_db
from app.core.security import hash_password
from app.models.models import (
    District, School, User, UserRole, RationShop, FoodItem, FoodCategory,
    Menu, MealRecord, MealSession, MealStatus, MealFoodItem, MealImage,
    Inventory, WasteRecord, WasteReason, Prediction, PredictionType,
    Recommendation, RecommendationStatus, Alert, AlertSeverity, AlertStatus,
    RiskLevel
)


async def seed_data():
    """Seed sample data if DB is empty."""
    await init_db()
    
    async with async_session() as db:
        # Check if already seeded
        result = await db.execute(select(District))
        if result.scalars().first() is not None:
            print("Database already contains data. Skipping seed.")
            return

        print("Seeding database with PM POSHAN Mid-Day Meal data...")

        # 1. Districts
        vizag = District(id=uuid.uuid4(), name="Visakhapatnam", code="DIST-01", state="Andhra Pradesh")
        vijayawada = District(id=uuid.uuid4(), name="Vijayawada", code="DIST-02", state="Andhra Pradesh")
        guntur = District(id=uuid.uuid4(), name="Guntur", code="DIST-03", state="Andhra Pradesh")
        tirupati = District(id=uuid.uuid4(), name="Tirupati", code="DIST-04", state="Andhra Pradesh")
        db.add_all([vizag, vijayawada, guntur, tirupati])
        await db.flush()

        # 2. Schools
        s1 = School(
            id=uuid.uuid4(),
            name="Zilla Parishad High School, MVP Colony",
            school_code="SCH-1001",
            district_id=vizag.id,
            address="Sector 4, MVP Colony, Visakhapatnam",
            student_count=450,
            latitude=17.7412,
            longitude=83.3321,
        )
        s2 = School(
            id=uuid.uuid4(),
            name="MPUPS Model Primary School, Benz Circle",
            school_code="SCH-1002",
            district_id=vijayawada.id,
            address="Benz Circle, Vijayawada",
            student_count=320,
            latitude=16.5062,
            longitude=80.6480,
        )
        s3 = School(
            id=uuid.uuid4(),
            name="Government High School, Brodipet",
            school_code="SCH-1003",
            district_id=guntur.id,
            address="4th Line Brodipet, Guntur",
            student_count=580,
            latitude=16.3067,
            longitude=80.4365,
        )
        s4 = School(
            id=uuid.uuid4(),
            name="PM POSHAN Demonstration School, Alipiri",
            school_code="SCH-1004",
            district_id=tirupati.id,
            address="Near Alipiri Gate, Tirupati",
            student_count=290,
            latitude=13.6288,
            longitude=79.4192,
        )
        db.add_all([s1, s2, s3, s4])
        await db.flush()

        # 3. Ration Shops
        rs1 = RationShop(
            id=uuid.uuid4(),
            shop_code="RS-501",
            name="Central Civil Supplies Depot - Vizag",
            district_id=vizag.id,
            address="Port Area, Visakhapatnam",
            capacity=10000.0,
            current_risk_score=0.15,
        )
        rs2 = RationShop(
            id=uuid.uuid4(),
            shop_code="RS-502",
            name="Fair Price Ration Shop #12 - Vijayawada",
            district_id=vijayawada.id,
            address="Governorpet, Vijayawada",
            capacity=8000.0,
            current_risk_score=0.35,
        )
        db.add_all([rs1, rs2])
        await db.flush()

        # 4. Users
        pwd_hash = hash_password("password123")
        admin = User(
            id=uuid.uuid4(),
            name="Dr. Rajesh Varma",
            email="admin@nutriguard.gov.in",
            phone="+919876543210",
            password_hash=pwd_hash,
            role=UserRole.ADMIN,
        )
        officer = User(
            id=uuid.uuid4(),
            name="Smt. Lakshmi Prasad",
            email="officer@nutriguard.gov.in",
            phone="+919876543211",
            password_hash=pwd_hash,
            role=UserRole.DISTRICT_OFFICER,
            district_id=vizag.id,
        )
        principal = User(
            id=uuid.uuid4(),
            name="K. Satyanarayana (Principal)",
            email="principal@zphs.edu.in",
            phone="+919876543212",
            password_hash=pwd_hash,
            role=UserRole.PRINCIPAL,
            district_id=vizag.id,
            school_id=s1.id,
        )
        teacher = User(
            id=uuid.uuid4(),
            name="M. Anitha (Nodal Teacher)",
            email="teacher@zphs.edu.in",
            phone="+919876543213",
            password_hash=pwd_hash,
            role=UserRole.TEACHER,
            district_id=vizag.id,
            school_id=s1.id,
        )
        ration_mgr = User(
            id=uuid.uuid4(),
            name="P. Ramesh (Depot Incharge)",
            email="ration@depot.gov.in",
            phone="+919876543214",
            password_hash=pwd_hash,
            role=UserRole.RATION_SHOP,
            district_id=vizag.id,
            ration_shop_id=rs1.id,
        )
        db.add_all([admin, officer, principal, teacher, ration_mgr])
        await db.flush()

        # Link Principal to School
        s1.principal_id = principal.id

        # 5. Food Items
        rice = FoodItem(id=uuid.uuid4(), name="Fortified Rice", category=FoodCategory.GRAIN, unit="kg", calories=360, protein=7.0, minimum_stock_level=100.0)
        dal = FoodItem(id=uuid.uuid4(), name="Toor Dal (Arhar)", category=FoodCategory.PULSE, unit="kg", calories=343, protein=22.0, minimum_stock_level=30.0)
        oil = FoodItem(id=uuid.uuid4(), name="Sunflower Cooking Oil", category=FoodCategory.OIL, unit="liters", calories=884, protein=0.0, minimum_stock_level=15.0)
        egg = FoodItem(id=uuid.uuid4(), name="Boiled Egg", category=FoodCategory.EGG, unit="pieces", calories=78, protein=6.3, minimum_stock_level=200.0)
        banana = FoodItem(id=uuid.uuid4(), name="Fresh Banana", category=FoodCategory.FRUIT, unit="pieces", calories=89, protein=1.1, minimum_stock_level=150.0)
        db.add_all([rice, dal, oil, egg, banana])
        await db.flush()

        # 6. Inventory
        inv1 = Inventory(id=uuid.uuid4(), school_id=s1.id, food_item_id=rice.id, quantity=240.0, unit="kg")
        inv2 = Inventory(id=uuid.uuid4(), school_id=s1.id, food_item_id=dal.id, quantity=45.0, unit="kg")
        inv3 = Inventory(id=uuid.uuid4(), school_id=s1.id, food_item_id=egg.id, quantity=500.0, unit="pieces")
        db.add_all([inv1, inv2, inv3])

        # 7. Meal Records
        today = date.today()
        m1 = MealRecord(
            id=uuid.uuid4(),
            school_id=s1.id,
            captured_by=teacher.id,
            meal_date=today,
            meal_session=MealSession.LUNCH,
            students_present=420,
            students_served=415,
            latitude=17.7412,
            longitude=83.3321,
            capture_time=datetime.now(timezone.utc),
            status=MealStatus.VERIFIED,
            nutrition_score=92.5,
            quantity_score=96.0,
            hygiene_score=94.0,
            overall_score=94.2,
        )
        m2 = MealRecord(
            id=uuid.uuid4(),
            school_id=s2.id,
            captured_by=teacher.id,
            meal_date=today - timedelta(days=1),
            meal_session=MealSession.LUNCH,
            students_present=310,
            students_served=295,
            latitude=16.5062,
            longitude=80.6480,
            capture_time=datetime.now(timezone.utc) - timedelta(days=1),
            status=MealStatus.NEEDS_REVIEW,
            nutrition_score=74.0,
            quantity_score=81.0,
            hygiene_score=68.0,
            overall_score=74.3,
        )
        db.add_all([m1, m2])
        await db.flush()

        # Meal Food Items & Images
        mf1 = MealFoodItem(id=uuid.uuid4(), meal_id=m1.id, food_item_name="Steamed Fortified Rice", estimated_quantity=50.0, confidence=0.98)
        mf2 = MealFoodItem(id=uuid.uuid4(), meal_id=m1.id, food_item_name="Sambar (Toor Dal & Vegetables)", estimated_quantity=35.0, confidence=0.95)
        mf3 = MealFoodItem(id=uuid.uuid4(), meal_id=m1.id, food_item_name="Boiled Egg", estimated_quantity=415.0, unit="pieces", confidence=0.99)
        db.add_all([mf1, mf2, mf3])

        img1 = MealImage(
            id=uuid.uuid4(),
            meal_id=m1.id,
            image_url="https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
            image_path="./storage/meals/sample_meal_1.jpg",
        )
        db.add_all([img1])

        # 8. Waste Record
        w1 = WasteRecord(
            id=uuid.uuid4(),
            school_id=s1.id,
            food_item_id=rice.id,
            meal_id=m1.id,
            quantity=3.5,
            unit="kg",
            reason=WasteReason.LEFTOVER,
            recorded_by=teacher.id,
            waste_date=today,
        )
        db.add(w1)

        # 9. AI Prediction & Alert
        p1 = Prediction(
            id=uuid.uuid4(),
            school_id=s2.id,
            prediction_type=PredictionType.SHORTAGE,
            target_date=today + timedelta(days=3),
            predicted_value=25.0,
            confidence=0.88,
            risk_level=RiskLevel.HIGH,
            features_json={"current_stock_kg": 12, "daily_consumption_kg": 15, "delivery_delay_days": 2},
        )
        db.add(p1)

        alt1 = Alert(
            id=uuid.uuid4(),
            school_id=s2.id,
            alert_type="SUPPLY_SHORTAGE_WARNING",
            severity=AlertSeverity.WARNING,
            title="High Shortage Risk: Toor Dal at MPUPS Benz Circle",
            message="Toor Dal stock predicted to run out in 3 days. Dispatch recommended from Ration Shop RS-502.",
            status=AlertStatus.ACTIVE,
        )
        db.add(alt1)

        rec1 = Recommendation(
            id=uuid.uuid4(),
            school_id=s1.id,
            recommendation_type="MENU_OPTIMIZATION",
            priority="HIGH",
            title="Increase Protein Intake with Egg Frequency Adjustment",
            description="Based on mid-day meal analytics, adding leafy greens twice weekly improves overall nutrition score by +8%.",
            expected_impact="Improved student nutrition compliance score to 98%",
            status=RecommendationStatus.PENDING,
        )
        db.add(rec1)

        await db.commit()
        print("Database seeded successfully!")


if __name__ == "__main__":
    asyncio.run(seed_data())
