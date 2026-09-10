"""NutriGuard AI — Food Waste Prediction ML Model Training Script.

Trains a Gradient Boosting & Random Forest Regressor on historical school meal & food waste metrics.
Saves model artifacts to backend/storage/ml_models/
"""

import os
import json
import numpy as np
import pandas as pd
import joblib
from datetime import datetime, timedelta
from typing import Dict, Any, Tuple

from sklearn.ensemble import GradientBoostingRegressor, RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

MODEL_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "storage", "ml_models")
MODEL_PATH = os.path.join(MODEL_DIR, "waste_prediction_model.joblib")
SCALER_PATH = os.path.join(MODEL_DIR, "scaler.joblib")
META_PATH = os.path.join(MODEL_DIR, "model_meta.json")

FEATURE_NAMES = [
    "student_count",
    "school_size",
    "attendance_rate",
    "meals_served",
    "day_of_week",
    "is_weekend",
    "is_holiday_season",
    "temperature_c",
    "menu_category_id",
    "hist_3day_avg_waste",
    "portion_size_g",
]


def generate_synthetic_historical_dataset(samples: int = 1200, seed: int = 42) -> pd.DataFrame:
    """Generate realistic synthetic training data for school meal food waste prediction."""
    np.random.seed(seed)
    
    school_sizes = np.random.choice([150, 300, 500, 800, 1200], size=samples)
    attendance_rates = np.random.uniform(0.70, 0.98, size=samples)
    student_counts = (school_sizes * attendance_rates).astype(int)
    
    meals_served = (student_counts * np.random.uniform(0.95, 1.05, size=samples)).astype(int)
    
    days_of_week = np.random.randint(0, 7, size=samples)
    is_weekend = (days_of_week >= 5).astype(int)
    
    is_holiday_season = np.random.choice([0, 1], size=samples, p=[0.85, 0.15])
    temperature_c = np.random.uniform(18.0, 38.0, size=samples)
    
    menu_categories = np.random.choice([0, 1, 2, 3], size=samples, p=[0.4, 0.3, 0.2, 0.1])
    # 0=Rice & Curry, 1=Roti & Sabzi, 2=Dal & Rice, 3=Special Feast
    
    portion_sizes = np.array([250, 220, 240, 300])[menu_categories] + np.random.uniform(-10, 10, size=samples)
    
    # Base expected waste rate per meal (grams)
    base_waste_per_meal = (
        0.035 * meals_served +
        1.5 * (days_of_week == 4) + # Fridays higher waste
        2.5 * is_holiday_season +
        0.08 * np.maximum(0, temperature_c - 25) +
        np.array([2.0, 1.2, 1.8, 4.5])[menu_categories]
    )
    
    # Generate realistic rolling waste trend
    hist_3day_avg_waste = np.maximum(0.5, base_waste_per_meal * np.random.uniform(0.85, 1.15, size=samples))
    
    # Target actual waste in kg
    noise = np.random.normal(0, 1.2, size=samples)
    waste_kg = np.maximum(0.2, base_waste_per_meal * 0.85 + hist_3day_avg_waste * 0.15 + noise)
    
    df = pd.DataFrame({
        "student_count": student_counts,
        "school_size": school_sizes,
        "attendance_rate": np.round(attendance_rates, 3),
        "meals_served": meals_served,
        "day_of_week": days_of_week,
        "is_weekend": is_weekend,
        "is_holiday_season": is_holiday_season,
        "temperature_c": np.round(temperature_c, 1),
        "menu_category_id": menu_categories,
        "hist_3day_avg_waste": np.round(hist_3day_avg_waste, 2),
        "portion_size_g": np.round(portion_sizes, 1),
        "waste_kg": np.round(waste_kg, 2),
    })
    
    return df


def train_waste_model() -> Dict[str, Any]:
    """Train Gradient Boosting model and save artifacts."""
    os.makedirs(MODEL_DIR, exist_ok=True)
    
    print("Generating dataset...")
    df = generate_synthetic_historical_dataset(samples=1500, seed=42)
    
    X = df[FEATURE_NAMES]
    y = df["waste_kg"]
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Primary Model: Gradient Boosting Regressor
    model = GradientBoostingRegressor(
        n_estimators=150,
        learning_rate=0.08,
        max_depth=4,
        random_state=42
    )
    model.fit(X_train_scaled, y_train)
    
    # Baseline Model: Random Forest Regressor
    rf_model = RandomForestRegressor(n_estimators=100, random_state=42)
    rf_model.fit(X_train_scaled, y_train)
    
    # Predictions & Metrics
    y_pred = model.predict(X_test_scaled)
    y_pred_rf = rf_model.predict(X_test_scaled)
    
    r2 = r2_score(y_test, y_pred)
    rmse = float(np.sqrt(mean_squared_error(y_test, y_pred)))
    mae = float(mean_absolute_error(y_test, y_pred))
    
    rf_r2 = r2_score(y_test, y_pred_rf)
    rf_rmse = float(np.sqrt(mean_squared_error(y_test, y_pred_rf)))
    
    # Feature Importances
    importances = dict(zip(FEATURE_NAMES, np.round(model.feature_importances_, 4).tolist()))
    
    # Save artifacts
    joblib.dump(model, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)
    
    meta_info = {
        "model_type": "GradientBoostingRegressor",
        "trained_at": datetime.now().isoformat(),
        "dataset_samples": len(df),
        "r2_score": round(r2, 4),
        "rmse": round(rmse, 4),
        "mae": round(mae, 4),
        "baseline_rf_r2": round(rf_r2, 4),
        "baseline_rf_rmse": round(rf_rmse, 4),
        "feature_importances": importances,
        "feature_names": FEATURE_NAMES,
    }
    
    with open(META_PATH, "w") as f:
        json.dump(meta_info, f, indent=2)
        
    print(f"Model trained successfully!")
    print(f"R2 Score: {r2:.4f}")
    print(f"RMSE: {rmse:.4f} kg")
    print(f"MAE: {mae:.4f} kg")
    print(f"Artifacts saved to {MODEL_DIR}")
    
    return meta_info


if __name__ == "__main__":
    train_waste_model()
