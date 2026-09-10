# NutriGuard AI - GitHub Pages Deployment

This directory contains the GitHub Pages deployment for the NutriGuard AI project.

## Deployment Link
🌐 **https://maneyash296-jpg.github.io/miday-meals-inpection-project/**

## Features
- ✅ PM POSHAN mid-day meal monitoring system
- ✅ Flutter mobile app with web support
- ✅ FastAPI backend with Groq vision/LLM integration
- ✅ ML waste prediction model
- ✅ School dashboards with real-time alerts

## How to Update
1. Build Flutter web: `cd nutriguard_ai && flutter build web --release`
2. Copy contents: `cp -r nutriguard_ai/build/web/* docs/`
3. Commit and push: `git add docs/ && git commit -m "update: Flutter web build" && git push`

## Backend
API: http://127.0.0.1:8000  
Health Check: http://127.0.0.1:8000/health

## Project Structure
```
miday-meals-inpection-project/
├── backend/          # FastAPI backend
├── nutriguard_ai/    # Flutter app
└── docs/             # GitHub Pages (this folder)
```
