from fastapi import APIRouter
from datetime import datetime
from app.core.config import settings

router = APIRouter()

@router.get("/")
async def health_check():
    """Health check endpoint for the API"""
    return {
        "status": "healthy",
        "service": "mongocraft-backend",
        "version": settings.VERSION,
        "timestamp": datetime.utcnow().isoformat(),
        "environment": settings.ENVIRONMENT
    }

@router.get("/ready")
async def readiness_check():
    """Readiness check endpoint"""
    # In the future, check database connections, external services, etc.
    return {
        "status": "ready",
        "service": "mongocraft-backend",
        "checks": {
            "database": "not_configured",  # Will be updated when DB is added
            "external_services": "ok"
        }
    }