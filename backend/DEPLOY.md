# NutriGuard AI — Backend Deployment Guide

## Deploy to Render (Free — Permanent Public URL)

### Step 1: Push backend to GitHub
```bash
cd "c:\Users\YASH MANE\OneDrive\Desktop\SIH\SIH\backend"
git init
git add .
git commit -m "NutriGuard AI backend"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/nutriguard-backend.git
git push -u origin main
```

### Step 2: Deploy on Render
1. Go to https://render.com → Sign up free
2. Click "New +" → "Web Service"
3. Connect your GitHub repo
4. Set these settings:
   - **Name**: nutriguard-backend
   - **Runtime**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add Environment Variables:
   - `DATABASE_URL` = `sqlite+aiosqlite:///./nutriguard.db`
   - `JWT_SECRET` = `nutriguard_super_secret_jwt_key_2024`
   - `GROQ_API_KEY` = `YOUR_GROQ_API_KEY`
   - `CORS_ORIGINS` = `*`
   - `ENVIRONMENT` = `production`
6. Click **Deploy**

### Step 3: Get your public URL
After deploy, Render gives you a URL like:
`https://nutriguard-backend.onrender.com`

### Step 4: Update Flutter APK with public URL
Replace the URL in:
`nutriguard_ai/lib/data/network/api_config.dart`

Change line 30:
```dart
return 'http://10.2.8.18:8000/api/v1';
```
To:
```dart
return 'https://nutriguard-backend.onrender.com/api/v1';
```

Then rebuild:
```powershell
cd "c:\Users\YASH MANE\OneDrive\Desktop\SIH\SIH\nutriguard_ai"
C:\tmp\flutter\bin\flutter.bat build apk --release --android-skip-build-dependency-validation
```
