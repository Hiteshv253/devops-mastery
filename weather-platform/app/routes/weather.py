from fastapi import APIRouter
from app.services.weather_service import get_weather

router = APIRouter(prefix="/api")


@router.get("/weather")
async def weather(city: str = "Vadodara"):
    return await get_weather(city)
