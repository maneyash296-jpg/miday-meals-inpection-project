"""NutriGuard AI — Application Configuration."""

from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """Central application settings loaded from environment variables."""

    # General
    PROJECT_NAME: str = "NutriGuard AI"
    API_V1_STR: str = "/api/v1"

    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./nutriguard.db"

    # Groq AI
    GROQ_API_KEY: str = ""
    GROQ_MODEL: str = "llama-3.3-70b-versatile"
    GROQ_VISION_MODEL: str = "llama-3.2-90b-vision-preview"

    # JWT
    JWT_SECRET: str = "CHANGE_THIS_SECRET"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Storage
    STORAGE_PATH: str = "./storage"

    # Environment
    ENVIRONMENT: str = "development"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Keep implementation endpoints out of the public hackathon/demo UI.
    # Set ENABLE_API_DOCS=true only for local API development.
    ENABLE_API_DOCS: bool = False

    # CORS
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080,http://10.0.2.2:8000"

    # Rate Limiting
    RATE_LIMIT: str = "100/minute"

    # Upload
    MAX_UPLOAD_SIZE: int = 10_485_760  # 10 MB

    @property
    def cors_origins_list(self) -> List[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT == "development"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}


settings = Settings()

# Ensure storage directory exists
os.makedirs(settings.STORAGE_PATH, exist_ok=True)
os.makedirs(os.path.join(settings.STORAGE_PATH, "meals"), exist_ok=True)
os.makedirs(os.path.join(settings.STORAGE_PATH, "reports"), exist_ok=True)
