from fastapi import APIRouter, UploadFile, File, Form
from app.services.ai_service import ask_devops_ai

router = APIRouter(prefix="/api")


# GET API
# Example:
# /api/chat?question=docker
@router.get("/chat")
async def get_chat(question: str):

    answer = await ask_devops_ai(question)

    return {"answer": answer}


# POST API with file upload
@router.post("/chat")
async def post_chat(question: str = Form(...), file: UploadFile = File(None)):

    file_content = ""

    if file:
        file_content = (await file.read()).decode("utf-8", errors="ignore")

    prompt = f"""
Question:

{question}

File Content:

{file_content}
"""

    answer = await ask_devops_ai(prompt)

    return {"answer": answer}
