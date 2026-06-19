import httpx

CITY_COORDINATES = {
    "Vadodara": (22.3072, 73.1812),
    "Ahmedabad": (23.0225, 72.5714),
    "Delhi": (28.6139, 77.2090),
    "Mumbai": (19.0760, 72.8777)
}


async def get_weather(city: str):

    latitude, longitude = CITY_COORDINATES.get(
        city,
        (22.3072, 73.1812)
    )

    url = (
        f"https://api.open-meteo.com/v1/forecast?"
        f"latitude={latitude}"
        f"&longitude={longitude}"
        f"&current_weather=true"
    )

    async with httpx.AsyncClient() as client:
        response = await client.get(url)

    data = response.json()

    return {
        "city": city,
        "temperature": data["current_weather"]["temperature"],
        "windspeed": data["current_weather"]["windspeed"],
        "weathercode": data["current_weather"]["weathercode"]
    }