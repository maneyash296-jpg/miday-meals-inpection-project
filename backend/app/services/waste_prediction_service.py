"""NutriGuard AI — ML-based Food Waste Prediction Service.

Uses scikit-learn Gradient Boosting model trained on historical meal metrics.
Groq is used to explain predictions, never to calculate numeric predictions.
"""

import os
import json
import numpy as np
import pandas as pd
import joblib
from typing import Dict, Any, List, Optional
from datetime import date, timedelta

from app.core.logging import logger

MODEL_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "storage", "ml_models")
MODEL_PATH = os.path.join(MODEL_DIR, "waste_prediction_model.joblib")
SCALER_PATH = os.path.join(MODEL_DIR, "scaler.joblib")
META_PATH = os.path.join(MODEL_DIR, "model_meta.json")


class WastePredictionService:
    """ML waste prediction service using trained GradientBoostingRegressor model."""

    def __init__(self):
        self.model = None
        self.scaler = None
        self.meta = {}
        self._load_model()

    def _load_model(self):
        """Load trained scikit-learn model and scaler if available."""
        try:
            if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
                self.model = joblib.load(MODEL_PATH)
                self.scaler = joblib.load(SCALER_PATH)
                if os.path.exists(META_PATH):
                    with open(META_PATH, "r") as f:
                        self.meta = json.load(f)
                logger.info(f"Loaded trained ML waste model (R2: {self.meta.get('r2_score', 'N/A')})")
        except Exception as e:
            logger.warning(f"Failed to load ML model artifact: {e}")
            self.model = None

    def predict_waste(
        self,
        historical_waste: List[float],
        student_counts: List[int],
        meals_served: List[int],
        school_size: int = 100,
        days_ahead: int = 7,
        temperature_c: float = 28.0,
        menu_category_id: int = 0,
        portion_size_g: float = 250.0,
    ) -> Dict[str, Any]:
        """Predict future food waste using trained ML model or regression fallback."""
        if not historical_waste or len(historical_waste) < 1:
            return self._insufficient_data_response(historical_waste, days_ahead)

        avg_hist_waste = float(np.mean(historical_waste))
        last_3day_avg = float(np.mean(historical_waste[-3:])) if len(historical_waste) >= 3 else avg_hist_waste
        avg_students = int(np.mean(student_counts)) if student_counts else school_size
        avg_meals = int(np.mean(meals_served)) if meals_served else avg_students

        # Use trained ML model if loaded
        if self.model and self.scaler:
            try:
                forecast = []
                preds = []
                today = date.today()

                for i in range(days_ahead):
                    target_date = today + timedelta(days=i + 1)
                    dow = target_date.weekday()
                    is_wknd = 1 if dow >= 5 else 0
                    is_holiday = 0

                    feature_cols = self.meta.get("feature_names", [
                        "student_count", "school_size", "attendance_rate", "meals_served",
                        "day_of_week", "is_weekend", "is_holiday_season", "temperature_c",
                        "menu_category_id", "hist_3day_avg_waste", "portion_size_g"
                    ])

                    attendance_rate = float(avg_students) / max(school_size, 1)

                    feature_df = pd.DataFrame([{
                        "student_count": avg_students,
                        "school_size": school_size,
                        "attendance_rate": attendance_rate,
                        "meals_served": avg_meals,
                        "day_of_week": dow,
                        "is_weekend": is_wknd,
                        "is_holiday_season": is_holiday,
                        "temperature_c": temperature_c,
                        "menu_category_id": menu_category_id,
                        "hist_3day_avg_waste": last_3day_avg,
                        "portion_size_g": portion_size_g,
                    }], columns=feature_cols)

                    scaled_vec = self.scaler.transform(feature_df)
                    pred_waste = float(self.model.predict(scaled_vec)[0])
                    pred_waste = max(0.1, pred_waste)
                    preds.append(pred_waste)

                    forecast.append({
                        "day": i + 1,
                        "date": str(target_date),
                        "predicted_waste_kg": round(pred_waste, 2),
                    })

                avg_pred = float(np.mean(preds))
                rmse = float(self.meta.get("rmse", 1.5))
                confidence = round(max(0.70, min(0.99, float(self.meta.get("r2_score", 0.95)))), 3)

                risk_level = self._calc_risk(avg_pred, avg_hist_waste)
                slope = (preds[-1] - preds[0]) / max(len(preds) - 1, 1)
                trend = "increasing" if slope > 0.1 else ("decreasing" if slope < -0.1 else "stable")

                return {
                    "prediction_type": "WASTE",
                    "predicted_value": round(avg_pred, 2),
                    "confidence": confidence,
                    "risk_level": risk_level,
                    "trend": trend,
                    "forecast": forecast,
                    "model_version": f"v2.0-{self.meta.get('model_type', 'GradientBoosting')}",
                    "features": {
                        "historical_days": len(historical_waste),
                        "avg_historical_waste": round(avg_hist_waste, 2),
                        "avg_predicted_waste": round(avg_pred, 2),
                        "rmse": round(rmse, 3),
                        "r2_score": self.meta.get("r2_score", 0.985),
                        "waste_per_student": round(avg_pred / max(avg_students, 1), 3),
                        "school_size": school_size,
                        "top_factors": self.meta.get("feature_importances", {}),
                    },
                }
            except Exception as e:
                logger.error(f"Error using trained ML model, falling back to analytical model: {e}")

        # Fallback linear regression calculation
        return self._analytical_linear_prediction(
            historical_waste, student_counts, meals_served, school_size, days_ahead
        )

    def _calc_risk(self, predicted: float, historical: float) -> str:
        if predicted > historical * 1.4:
            return "CRITICAL"
        elif predicted > historical * 1.2:
            return "HIGH"
        elif predicted > historical * 1.05:
            return "MEDIUM"
        return "LOW"

    def _analytical_linear_prediction(
        self,
        historical_waste: List[float],
        student_counts: List[int],
        meals_served: List[int],
        school_size: int,
        days_ahead: int,
    ) -> Dict[str, Any]:
        waste_arr = np.array(historical_waste, dtype=float)
        n = len(waste_arr)
        X = np.arange(n).reshape(-1, 1)
        y = waste_arr

        X_mean, y_mean = X.mean(), y.mean()
        slope = np.sum((X.flatten() - X_mean) * (y - y_mean)) / max(np.sum((X.flatten() - X_mean) ** 2), 1e-9)
        intercept = y_mean - slope * X_mean

        future_indices = np.arange(n, n + days_ahead)
        predictions = np.clip(slope * future_indices + intercept, 0, None)

        avg_pred = float(np.mean(predictions))
        risk_level = self._calc_risk(avg_pred, float(y_mean))
        trend = "increasing" if slope > 0.05 else ("decreasing" if slope < -0.05 else "stable")

        return {
            "prediction_type": "WASTE",
            "predicted_value": round(avg_pred, 2),
            "confidence": 0.85,
            "risk_level": risk_level,
            "trend": trend,
            "forecast": [
                {
                    "day": i + 1,
                    "date": str(date.today() + timedelta(days=i + 1)),
                    "predicted_waste_kg": round(float(predictions[i]), 2),
                }
                for i in range(days_ahead)
            ],
            "model_version": "v1.0-linear-fallback",
            "features": {
                "historical_days": n,
                "avg_historical_waste": round(float(y_mean), 2),
                "slope": round(float(slope), 4),
            },
        }

    def _insufficient_data_response(self, data: List[float], days_ahead: int) -> Dict[str, Any]:
        avg = float(np.mean(data)) if data else 15.0
        return {
            "prediction_type": "WASTE",
            "predicted_value": round(avg, 2),
            "confidence": 0.5,
            "risk_level": "LOW",
            "trend": "stable",
            "forecast": [
                {
                    "day": i + 1,
                    "date": str(date.today() + timedelta(days=i + 1)),
                    "predicted_waste_kg": round(avg, 2),
                }
                for i in range(days_ahead)
            ],
            "model_version": "v1.0-baseline",
            "features": {"note": "Baseline default forecast"},
        }


waste_prediction_service = WastePredictionService()
