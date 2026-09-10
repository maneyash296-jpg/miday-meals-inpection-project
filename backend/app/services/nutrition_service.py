"""NutriGuard AI — Nutrition Service.

Calculates nutritional values from PostgreSQL food item data.
Compares against administrative targets. No medical diagnosis.
"""

from typing import List, Dict, Any
from app.core.logging import logger


# Default government nutrition targets (per student per meal)
DEFAULT_NUTRITION_TARGETS = {
    "calories": 700,     # kcal
    "protein": 20,       # g
    "carbohydrates": 100, # g
    "fat": 15,           # g
}


class NutritionService:
    """Calculate nutrition scores from food item data stored in PostgreSQL."""

    def calculate_meal_nutrition(
        self,
        detected_items: List[Dict[str, Any]],
        food_items_db: List[Dict[str, Any]],
        students_served: int = 1,
        targets: Dict[str, float] = None,
    ) -> Dict[str, Any]:
        """
        Calculate total nutrition from detected items and compare against targets.

        Args:
            detected_items: AI-detected items [{"name": ..., "estimated_quantity": ...}]
            food_items_db:  DB records [{"name": ..., "calories": ..., "protein": ..., ...}]
            students_served: Number of students
            targets: Override nutrition targets
        """
        if targets is None:
            targets = DEFAULT_NUTRITION_TARGETS.copy()

        # Build lookup by name (case-insensitive)
        db_lookup = {item["name"].strip().lower(): item for item in food_items_db}

        total_calories = 0.0
        total_protein = 0.0
        total_carbs = 0.0
        total_fat = 0.0
        item_breakdown = []

        for det in detected_items:
            name = det.get("name", "").strip().lower()
            qty = det.get("estimated_quantity", 0)
            db_item = db_lookup.get(name)

            if db_item and qty > 0:
                cal = db_item.get("calories", 0) * qty * 10
                pro = db_item.get("protein", 0) * qty * 10
                carb = db_item.get("carbohydrates", 0) * qty * 10
                fat_val = db_item.get("fat", 0) * qty * 10

                total_calories += cal
                total_protein += pro
                total_carbs += carb
                total_fat += fat_val

                item_breakdown.append({
                    "name": det.get("name", name.title()),
                    "quantity_kg": qty,
                    "calories": round(cal, 1),
                    "protein": round(pro, 1),
                    "carbohydrates": round(carb, 1),
                    "fat": round(fat_val, 1),
                })

        # Per-student values
        per_student = {}
        if students_served > 0:
            per_student = {
                "calories": round(total_calories / students_served, 1),
                "protein": round(total_protein / students_served, 1),
                "carbohydrates": round(total_carbs / students_served, 1),
                "fat": round(total_fat / students_served, 1),
            }
        else:
            per_student = {
                "calories": round(total_calories, 1),
                "protein": round(total_protein, 1),
                "carbohydrates": round(total_carbs, 1),
                "fat": round(total_fat, 1),
            }

        # Score: percentage of target met (capped at 100)
        scores = {}
        for nutrient, target_val in targets.items():
            actual = per_student.get(nutrient, 0)
            if target_val > 0:
                scores[nutrient] = round(min(actual / target_val, 1.0) * 100, 1)
            else:
                scores[nutrient] = 100.0

        overall_score = round(sum(scores.values()) / len(scores), 1) if scores else 0.0

        return {
            "total": {
                "calories": round(total_calories, 1),
                "protein": round(total_protein, 1),
                "carbohydrates": round(total_carbs, 1),
                "fat": round(total_fat, 1),
            },
            "per_student": per_student,
            "targets": targets,
            "scores": scores,
            "overall_nutrition_score": overall_score,
            "item_breakdown": item_breakdown,
            "students_served": students_served,
        }


nutrition_service = NutritionService()
