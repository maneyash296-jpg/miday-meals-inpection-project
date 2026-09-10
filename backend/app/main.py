import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from app.core.config import settings
from app.api.api import api_router
from app.db.seed import seed_data


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Auto-seed DB on startup if empty
    try:
        await seed_data()
    except Exception as e:
        print(f"Startup DB seed log: {e}")
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json" if settings.ENABLE_API_DOCS else None,
    docs_url="/docs" if settings.ENABLE_API_DOCS else None,
    redoc_url=None,
    description="Backend API for NutriGuard AI - School Mid-Day Meal Monitoring",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
cors_origins = settings.CORS_ORIGINS.strip()
if cors_origins == "*":
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
elif cors_origins:
    origins = [o.strip() for o in cors_origins.split(",") if o.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    )

app.include_router(api_router, prefix=settings.API_V1_STR)

# Mount static files
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")


@app.get("/", include_in_schema=False)
async def serve_index():
    index_path = os.path.join(static_dir, "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"message": "Welcome to NutriGuard AI API", "docs": "/docs"}


@app.get("/health")
def health_check():
    return {"status": "healthy", "version": "1.0.0", "project": settings.PROJECT_NAME}
