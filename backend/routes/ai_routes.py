from backend.models.diary import DiaryEntry
from fastapi import APIRouter, Depends
from backend.schemas.diary import AIQueryLogCreate
from backend.services.ai_service import get_ai_logs, insert_ai_log
from backend.dependencies.db import get_db
from typing import Annotated
from mysql.connector.connection_cext import CMySQLConnection
# from backend.dependencies.auth import get_current_user

router = APIRouter(prefix="/ai_logs", tags=["AI Logs"])

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