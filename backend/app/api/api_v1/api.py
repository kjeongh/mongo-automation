from fastapi import APIRouter
from app.api.api_v1.endpoints import clusters, health

api_router = APIRouter()

# Include endpoint routers
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(clusters.router, prefix="/clusters", tags=["clusters"])