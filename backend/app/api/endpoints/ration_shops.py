"""NutriGuard AI — Ration Shops API Endpoints.

Handles ration shop dashboard, inventory management, allocations,
deliveries (dispatch), and search functionality.
"""

from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status as http_status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from uuid import UUID
import uuid as _uuid
from datetime import date

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.models import (
    RationShop, Inventory, FoodItem, RationAllocation, RationDelivery,
    DeliveryItem, School, Alert, User, AllocationStatus, DeliveryStatus
)
from app.schemas.schemas import (
    RationShopResponse, RationShopDashboard, InventoryResponse,
    AllocationCreate, AllocationResponse, DeliveryCreate, DeliveryResponse,
    DeliveryReceive,
)

router = APIRouter()


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _fmt_shop(s: RationShop) -> dict:
    return {
        "id": str(s.id),
        "shop_code": s.shop_code,
        "name": s.name,
        "district_id": str(s.district_id),
        "address": s.address,
        "latitude": s.latitude,
        "longitude": s.longitude,
        "capacity": s.capacity,
        "current_risk_score": s.current_risk_score,
        "active": s.active,
        "created_at": s.created_at.isoformat() if s.created_at else None,
    }


def _fmt_inventory(inv: Inventory) -> dict:
    food = inv.food_item
    return {
        "id": str(inv.id),
        "ration_shop_id": str(inv.ration_shop_id) if inv.ration_shop_id else None,
        "food_item_id": str(inv.food_item_id),
        "food_item": {
            "id": str(food.id),
            "name": food.name,
            "category": food.category.value if hasattr(food.category, "value") else str(food.category),
            "unit": food.unit,
            "calories": food.calories,
            "protein": food.protein,
        } if food else None,
        "quantity": inv.quantity,
        "unit": inv.unit,
        "minimum_quantity": inv.minimum_quantity,
        "is_low_stock": inv.quantity <= inv.minimum_quantity,
        "last_updated": inv.last_updated.isoformat() if inv.last_updated else None,
    }


# ─── List / Get Ration Shops ─────────────────────────────────────────────────

@router.get("/", response_model=List[dict])
async def list_ration_shops(
    limit: int = Query(100, ge=1, le=500),
    q: Optional[str] = Query(None, description="Search query"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """List all ration shops, optionally filtered by search query."""
    stmt = select(RationShop)
    if q:
        pattern = f"%{q.strip()}%"
        stmt = stmt.where(
            or_(
                RationShop.name.ilike(pattern),
                RationShop.shop_code.ilike(pattern),
                RationShop.address.ilike(pattern),
            )
        )
    stmt = stmt.limit(limit)
    result = await db.execute(stmt)
    shops = result.scalars().all()
    return [_fmt_shop(s) for s in shops]


@router.get("/dashboard")
async def get_ration_shop_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Get dashboard data for the currently logged-in ration shop manager."""
    ration_shop_id = current_user.ration_shop_id
    if not ration_shop_id:
        # Fallback: return first ration shop if admin/district
        result = await db.execute(select(RationShop).limit(1))
        shop = result.scalars().first()
        if not shop:
            return {
                "shop": None,
                "total_stock_items": 0,
                "low_stock_count": 0,
                "pending_allocations": 0,
                "pending_deliveries": 0,
                "schools_served": 0,
                "risk_score": 0.0,
                "inventory": [],
                "recent_deliveries": [],
                "alerts": [],
                "recommendations": [],
            }
        ration_shop_id = str(shop.id)

    shop_uuid = _uuid.UUID(ration_shop_id) if isinstance(ration_shop_id, str) else ration_shop_id

    # Fetch shop
    result = await db.execute(select(RationShop).where(RationShop.id == shop_uuid))
    shop = result.scalars().first()
    if not shop:
        raise HTTPException(status_code=404, detail="Ration shop not found")

    # Fetch inventory
    inv_result = await db.execute(
        select(Inventory).where(Inventory.ration_shop_id == shop_uuid)
    )
    inventory = inv_result.scalars().all()
    inv_list = [_fmt_inventory(i) for i in inventory]

    low_stock = [i for i in inv_list if i["is_low_stock"]]

    # Fetch pending allocations
    alloc_result = await db.execute(
        select(RationAllocation).where(
            RationAllocation.ration_shop_id == shop_uuid,
            RationAllocation.status == AllocationStatus.PENDING
        )
    )
    pending_allocs = alloc_result.scalars().all()

    # Fetch pending deliveries
    del_result = await db.execute(
        select(RationDelivery).where(
            RationDelivery.ration_shop_id == shop_uuid,
            RationDelivery.status == DeliveryStatus.PENDING
        )
    )
    pending_deliveries = del_result.scalars().all()

    # Count unique schools served
    school_result = await db.execute(
        select(RationAllocation.school_id).where(
            RationAllocation.ration_shop_id == shop_uuid
        ).distinct()
    )
    schools_served = len(school_result.scalars().all())

    # Fetch alerts for this ration shop
    alert_result = await db.execute(
        select(Alert).where(Alert.ration_shop_id == shop_uuid).order_by(Alert.created_at.desc()).limit(5)
    )
    alerts = alert_result.scalars().all()
    alerts_list = [
        {
            "id": str(a.id),
            "title": a.title,
            "message": a.message,
            "severity": a.severity.value if hasattr(a.severity, "value") else str(a.severity),
            "status": a.status.value if hasattr(a.status, "value") else str(a.status),
            "created_at": a.created_at.isoformat() if a.created_at else None,
        }
        for a in alerts
    ]

    # Recent deliveries
    recent_del_result = await db.execute(
        select(RationDelivery).where(
            RationDelivery.ration_shop_id == shop_uuid
        ).order_by(RationDelivery.created_at.desc()).limit(5)
    )
    recent_deliveries = recent_del_result.scalars().all()
    deliveries_list = [
        {
            "id": str(d.id),
            "delivery_number": d.delivery_number,
            "school_id": str(d.school_id),
            "status": d.status.value if hasattr(d.status, "value") else str(d.status),
            "dispatch_time": d.dispatch_time.isoformat() if d.dispatch_time else None,
            "received_time": d.received_time.isoformat() if d.received_time else None,
        }
        for d in recent_deliveries
    ]

    return {
        "shop": _fmt_shop(shop),
        "total_stock_items": len(inventory),
        "low_stock_count": len(low_stock),
        "pending_allocations": len(pending_allocs),
        "pending_deliveries": len(pending_deliveries),
        "schools_served": schools_served,
        "risk_score": float(shop.current_risk_score or 0.0),
        "inventory": inv_list,
        "recent_deliveries": deliveries_list,
        "alerts": alerts_list,
        "recommendations": [],
    }


# ─── Search (MUST be before /{shop_id} to avoid path collision) ──────────────

@router.get("/search/inventory")
async def search_ration_inventory(
    q: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """Search ration shop inventory across all shops."""
    ration_shop_id = current_user.ration_shop_id
    pattern = f"%{q.strip()}%"

    stmt = select(Inventory, FoodItem).join(FoodItem, Inventory.food_item_id == FoodItem.id).where(
        FoodItem.name.ilike(pattern)
    )
    if ration_shop_id:
        shop_uuid = _uuid.UUID(ration_shop_id) if isinstance(ration_shop_id, str) else ration_shop_id
        stmt = stmt.where(Inventory.ration_shop_id == shop_uuid)

    stmt = stmt.limit(limit)
    result = await db.execute(stmt)
    rows = result.all()

    return [
        {
            "inventory_id": str(inv.id),
            "food_item_id": str(fi.id),
            "food_item_name": fi.name,
            "category": fi.category.value if hasattr(fi.category, "value") else str(fi.category),
            "quantity": inv.quantity,
            "unit": inv.unit,
            "is_low_stock": inv.quantity <= inv.minimum_quantity,
            "ration_shop_id": str(inv.ration_shop_id) if inv.ration_shop_id else None,
        }
        for inv, fi in rows
    ]


@router.get("/search/schools")
async def search_served_schools(
    q: str = Query(..., min_length=1, description="Search schools"),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Search schools that this ration shop serves."""
    pattern = f"%{q.strip()}%"
    stmt = select(School).where(
        or_(
            School.name.ilike(pattern),
            School.school_code.ilike(pattern),
            School.address.ilike(pattern),
        )
    ).limit(limit)
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


@router.get("/{shop_id}", response_model=dict)
async def get_ration_shop(
    shop_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Get a specific ration shop by ID."""
    result = await db.execute(select(RationShop).where(RationShop.id == shop_id))
    shop = result.scalars().first()
    if not shop:
        raise HTTPException(status_code=404, detail="Ration shop not found")
    return _fmt_shop(shop)

# ─── Inventory ────────────────────────────────────────────────────────────────

@router.get("/{shop_id}/inventory")
async def get_shop_inventory(
    shop_id: UUID,
    q: Optional[str] = Query(None, description="Search inventory items"),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Get inventory for a ration shop, with optional search."""
    stmt = select(Inventory).where(Inventory.ration_shop_id == shop_id)
    result = await db.execute(stmt)
    inventory = result.scalars().all()
    inv_list = [_fmt_inventory(i) for i in inventory]

    if q:
        q_lower = q.strip().lower()
        inv_list = [
            i for i in inv_list
            if q_lower in (i["food_item"]["name"].lower() if i["food_item"] else "")
            or q_lower in i["unit"].lower()
        ]

    return inv_list


@router.post("/{shop_id}/inventory/receive")
async def receive_stock(
    shop_id: UUID,
    food_item_id: UUID,
    quantity: float,
    notes: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Record stock receipt for a ration shop inventory item."""
    result = await db.execute(
        select(Inventory).where(
            Inventory.ration_shop_id == shop_id,
            Inventory.food_item_id == food_item_id
        )
    )
    inv = result.scalars().first()
    if inv:
        inv.quantity += quantity
    else:
        inv = Inventory(
            id=_uuid.uuid4(),
            ration_shop_id=shop_id,
            food_item_id=food_item_id,
            quantity=quantity,
            unit="kg",
        )
        db.add(inv)
    await db.commit()
    await db.refresh(inv)
    return {"success": True, "message": f"Received {quantity} units", "inventory": _fmt_inventory(inv)}


# ─── Allocations ─────────────────────────────────────────────────────────────

@router.get("/{shop_id}/allocations")
async def get_allocations(
    shop_id: UUID,
    status_filter: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Get allocations for a ration shop."""
    stmt = select(RationAllocation).where(RationAllocation.ration_shop_id == shop_id)
    result = await db.execute(stmt)
    allocations = result.scalars().all()

    def fmt_alloc(a):
        return {
            "id": str(a.id),
            "school_id": str(a.school_id),
            "food_item_id": str(a.food_item_id),
            "food_item_name": a.food_item.name if a.food_item else "Unknown",
            "allocated_quantity": a.allocated_quantity,
            "recommended_quantity": a.recommended_quantity,
            "allocation_date": str(a.allocation_date),
            "status": a.status.value if hasattr(a.status, "value") else str(a.status),
            "created_at": a.created_at.isoformat() if a.created_at else None,
        }

    items = [fmt_alloc(a) for a in allocations]
    if status_filter:
        items = [i for i in items if i["status"].upper() == status_filter.upper()]
    return items


@router.post("/{shop_id}/allocations", status_code=http_status.HTTP_201_CREATED)
async def create_allocation(
    shop_id: UUID,
    alloc_in: AllocationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Create a new school ration allocation."""
    alloc = RationAllocation(
        id=_uuid.uuid4(),
        ration_shop_id=shop_id,
        school_id=alloc_in.school_id,
        food_item_id=alloc_in.food_item_id,
        allocated_quantity=alloc_in.allocated_quantity,
        recommended_quantity=alloc_in.recommended_quantity,
        allocation_date=alloc_in.allocation_date,
        status=AllocationStatus.PENDING,
    )
    db.add(alloc)
    await db.commit()
    await db.refresh(alloc)
    return {"success": True, "id": str(alloc.id), "status": "PENDING"}


# ─── Deliveries (Dispatch) ───────────────────────────────────────────────────

@router.get("/{shop_id}/deliveries")
async def get_deliveries(
    shop_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Get all deliveries for a ration shop."""
    result = await db.execute(
        select(RationDelivery).where(
            RationDelivery.ration_shop_id == shop_id
        ).order_by(RationDelivery.created_at.desc()).limit(50)
    )
    deliveries = result.scalars().all()
    return [
        {
            "id": str(d.id),
            "delivery_number": d.delivery_number,
            "school_id": str(d.school_id),
            "vehicle_number": d.vehicle_number,
            "driver_name": d.driver_name,
            "status": d.status.value if hasattr(d.status, "value") else str(d.status),
            "dispatch_time": d.dispatch_time.isoformat() if d.dispatch_time else None,
            "received_time": d.received_time.isoformat() if d.received_time else None,
            "items": [
                {
                    "food_item_id": str(item.food_item_id),
                    "food_item_name": item.food_item.name if item.food_item else "Unknown",
                    "dispatched_quantity": item.dispatched_quantity,
                    "received_quantity": item.received_quantity,
                }
                for item in d.items
            ],
            "created_at": d.created_at.isoformat() if d.created_at else None,
        }
        for d in deliveries
    ]


@router.post("/{shop_id}/deliveries", status_code=http_status.HTTP_201_CREATED)
async def create_delivery(
    shop_id: UUID,
    delivery_in: DeliveryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_active_user),
) -> Any:
    """Dispatch a ration delivery from this shop to a school."""
    import random
    delivery_number = f"DLV-{random.randint(10000, 99999)}"

    delivery = RationDelivery(
        id=_uuid.uuid4(),
        ration_shop_id=shop_id,
        school_id=delivery_in.school_id,
        delivery_number=delivery_number,
        vehicle_number=delivery_in.vehicle_number,
        driver_name=delivery_in.driver_name,
        expected_delivery=delivery_in.expected_delivery,
        status=DeliveryStatus.DISPATCHED,
    )
    db.add(delivery)
    await db.flush()

    for item in delivery_in.items:
        di = DeliveryItem(
            id=_uuid.uuid4(),
            delivery_id=delivery.id,
            food_item_id=item.food_item_id,
            expected_quantity=item.expected_quantity,
            dispatched_quantity=item.dispatched_quantity,
        )
        db.add(di)

        # Deduct from shop inventory
        inv_result = await db.execute(
            select(Inventory).where(
                Inventory.ration_shop_id == shop_id,
                Inventory.food_item_id == item.food_item_id
            )
        )
        inv = inv_result.scalars().first()
        if inv and inv.quantity >= item.dispatched_quantity:
            inv.quantity -= item.dispatched_quantity

    await db.commit()
    return {
        "success": True,
        "delivery_number": delivery_number,
        "id": str(delivery.id),
        "status": "DISPATCHED",
        "message": "Ration dispatched successfully",
    }

