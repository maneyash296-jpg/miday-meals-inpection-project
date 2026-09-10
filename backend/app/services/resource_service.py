"""NutriGuard AI — Resource Analysis Service.

Calculates resource utilization, waste percentages, inventory turnover,
surplus/shortage, and estimated savings using PostgreSQL historical data.
"""

from typing import Dict, Any, List
from app.core.logging import logger


class ResourceAnalysisService:
    """Deterministic resource analysis — no AI involved."""

    def analyze_resources(
        self,
        consumed: float,
        wasted: float,
        total_available: float,
        cost_per_kg: float = 30.0,  # Average INR per kg
    ) -> Dict[str, Any]:
        """Calculate resource utilization metrics."""
        total_used = consumed + wasted

        waste_percentage = 0.0
        if total_used > 0:
            waste_percentage = round((wasted / total_used) * 100, 1)

        utilization = 0.0
        if total_available > 0:
            utilization = round((consumed / total_available) * 100, 1)

        surplus = max(total_available - total_used, 0)
        shortage = max(total_used - total_available, 0)

        avoidable_waste = wasted * 0.7  # 70% of waste is avoidable
        savings_kg = round(avoidable_waste, 1)
        savings_inr = round(avoidable_waste * cost_per_kg, 0)

        return {
            "consumed_kg": round(consumed, 1),
            "wasted_kg": round(wasted, 1),
            "total_available_kg": round(total_available, 1),
            "waste_percentage": waste_percentage,
            "utilization_percentage": utilization,
            "surplus_kg": round(surplus, 1),
            "shortage_kg": round(shortage, 1),
            "avoidable_waste_kg": savings_kg,
            "estimated_savings_inr": savings_inr,
            "resource_efficiency": round(100 - waste_percentage, 1),
        }

    def calculate_inventory_turnover(
        self,
        total_consumed: float,
        average_inventory: float,
        days: int = 30,
    ) -> Dict[str, Any]:
        """Inventory turnover for a period."""
        turnover_ratio = 0.0
        if average_inventory > 0:
            turnover_ratio = round(total_consumed / average_inventory, 2)

        days_of_supply = 0.0
        daily_consumption = total_consumed / max(days, 1)
        if daily_consumption > 0 and average_inventory > 0:
            days_of_supply = round(average_inventory / daily_consumption, 1)

        return {
            "turnover_ratio": turnover_ratio,
            "days_of_supply": days_of_supply,
            "daily_consumption": round(daily_consumption, 1),
            "average_inventory": round(average_inventory, 1),
            "period_days": days,
        }

    def aggregate_school_resources(
        self,
        waste_records: List[Dict[str, Any]],
        meal_records: List[Dict[str, Any]],
        inventory_records: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """Aggregate resource data for a school."""
        total_waste = sum(r.get("quantity", 0) for r in waste_records if r.get("unit", "kg") == "kg")
        total_consumed = sum(
            sum(item.get("estimated_quantity", 0) for item in r.get("detected_items", []) if item.get("unit", "kg") == "kg")
            for r in meal_records
        )
        total_inventory = sum(r.get("quantity", 0) for r in inventory_records if r.get("unit", "kg") == "kg")

        resource_analysis = self.analyze_resources(
            consumed=total_consumed,
            wasted=total_waste,
            total_available=total_inventory + total_consumed + total_waste,
        )

        return resource_analysis


resource_service = ResourceAnalysisService()
