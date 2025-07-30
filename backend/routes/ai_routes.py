from backend.models.diary import DiaryEntry
from fastapi import APIRouter, Depends, HTTPException
from backend.schemas.diary import AIQueryLogCreate
from backend.services.ai_service import get_ai_logs, insert_ai_log
from backend.dependencies.db import get_db
from typing import Annotated
from mysql.connector.connection_cext import CMySQLConnection
from pydantic import BaseModel
import os
# from backend.dependencies.auth import get_current_user

router = APIRouter(prefix="/ai_logs", tags=["AI Logs"])


API_KEY = os.getenv("GEMINI_API_KEY")  # Railway면 환경변수 등록해줘야 함
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={API_KEY}"

class PromptRequest(BaseModel):
    prompt: str

@router.post("/generate-diary")
def generate_diary(req: PromptRequest):
    body = {
        "contents": [
            {
                "parts": [
                    {"text": req.prompt}
                ]
            }
        ]
    }

    headers = {"Content-Type": "application/json"}
    res = requests.post(GEMINI_URL, headers=headers, json=body)

    if res.status_code != 200:
        raise HTTPException(status_code=500, detail="Gemini API 호출 실패")

    data = res.json()
    try:
        return {"diary": data["candidates"][0]["content"]["parts"][0]["text"]}
    except:
        raise HTTPException(status_code=500, detail="Gemini 응답 파싱 오류")

# 대화 내용 불러오기
@router.get("/ai_logs/{diary_id}/ai_logs")
async def get_ai_logs_route(
    diary_id: int,
    db: Annotated[CMySQLConnection, Depends(get_db)],
    # user_id: int = Depends(get_current_user)
):
    logs = get_ai_logs(diary_id)
    return {"logs": logs}

# 채팅
@router.post("/ai_logs/{diary_id}/ai_logs")
async def chat_with_ai(
    diary_id: int,
    input: AIQueryLogCreate,
    db: Annotated[CMySQLConnection, Depends(get_db)],
    # user_id: int = Depends(get_current_user)
):
    # 임시로 AI 응답을 저장하는 로직
    result = insert_ai_log(diary_id, input.content, "user")
    return {"reply": "AI 응답이 준비되었습니다.", "log_id": result["log_id"]}