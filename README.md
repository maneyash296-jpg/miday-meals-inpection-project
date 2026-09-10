# Mid-Day Meals Inspection Project (NutriGuard AI)

PM POSHAN / mid-day meal monitoring system: Flutter mobile app + FastAPI backend with meal photo analysis, school dashboards, alerts, and a trained waste-prediction model.

## Repository layout

- `backend/` — FastAPI API, Groq vision/LLM integration, ML waste model
- `nutriguard_ai/` — Flutter app (Android / web)

App icons and favicon are the exact logos from the original project zip (`ic_launcher` + `web/favicon.png`).

## Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
# set GROQ_API_KEY in .env
python run_server.py
```

API: http://127.0.0.1:8000  
Health: http://127.0.0.1:8000/health

## Flutter app

```bash
cd nutriguard_ai
flutter pub get
flutter run
# or build APK:
flutter build apk --release
```

## Notes

- Do not commit `.env`. Use `.env.example`.
- Trained waste model files are in `backend/storage/ml_models/`.
