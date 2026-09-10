"""NutriGuard AI — Menu Compliance Service.

Deterministic comparison of expected vs detected meal items.
Groq is NOT used for official compliance determination.
"""

from typing import List, Dict, Any, Optional
from app.core.logging import logger


class MenuComplianceService:
    """Compare detected food items against the expected menu."""

    def check_compliance(
        self,
        expected_items: List[Dict[str, Any]],
        detected_items: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Compare expected menu items against AI-detected items.

        Args:
            expected_items: List of dicts with at least {"name": str, "required_quantity": float}
            detected_items: List of dicts with at least {"name": str, "estimated_quantity": float, "confidence": float}

        Returns:
            Dict with compliance results.
        """
        expected_names = {item["name"].strip().lower() for item in expected_items}
        detected_names = {item["name"].strip().lower() for item in detected_items}

        # Items found (substring matching)
        matched = {e for e in expected_names if any(e in d or d in e for d in detected_names)} | \
                  {d for d in detected_names if any(d in e or e in d for e in expected_names)}
        missing = expected_names - matched
        extra = detected_names - matched

        # Quantity compliance
        quantity_results = []
        for exp in expected_items:
            exp_name = exp["name"].strip().lower()
            det_match = next((d for d in detected_items if exp_name in d["name"].strip().lower() or d["name"].strip().lower() in exp_name), None)

            result = {
                "item": exp["name"],
                "expected_quantity": exp.get("required_quantity", 0),
                "detected_quantity": 0.0,
                "status": "MISSING",
                "quantity_match": 0.0,
            }
            if det_match:
                det_qty = det_match.get("estimated_quantity", 0)
                exp_qty = exp.get("required_quantity", 0)
                result["detected_quantity"] = det_qty
                if exp_qty > 0:
                    match_pct = min(det_qty / exp_qty, 1.0) * 100
                    result["quantity_match"] = round(match_pct, 1)
                else:
                    result["quantity_match"] = 100.0

                if result["quantity_match"] >= 80:
                    result["status"] = "COMPLIANT"
                elif result["quantity_match"] >= 50:
                    result["status"] = "PARTIAL"
                else:
                    result["status"] = "INSUFFICIENT"

            quantity_results.append(result)

        # Overall score
        if len(expected_items) > 0:
            item_score = (len(matched) / len(expected_items)) * 100
        else:
            item_score = 100.0

        avg_quantity_match = 0.0
        if quantity_results:
            avg_quantity_match = sum(r["quantity_match"] for r in quantity_results) / len(quantity_results)

        overall_compliance = round((item_score * 0.6 + avg_quantity_match * 0.4), 1)

        return {
            "overall_score": overall_compliance,
            "item_score": round(item_score, 1),
            "quantity_score": round(avg_quantity_match, 1),
            "matched_items": [i.title() for i in matched],
            "missing_items": [i.title() for i in missing],
            "extra_items": [i.title() for i in extra],
            "item_details": quantity_results,
            "total_expected": len(expected_items),
            "total_detected": len(detected_items),
            "is_compliant": overall_compliance >= 70,
        }


menu_compliance_service = MenuComplianceService()
