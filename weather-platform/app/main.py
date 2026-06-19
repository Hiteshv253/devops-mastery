from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates

from app.routes.weather import router as weather_router
from app.routes.chat import router as chat_router


app = FastAPI(title="Weather Platform")

templates = Jinja2Templates(directory="app/templates")

app.include_router(weather_router)
app.include_router(chat_router)


@app.get("/")
async def home(request: Request):

    return templates.TemplateResponse(
        request=request,
        name="index.html"
    )