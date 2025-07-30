from fastapi import APIRouter, Depends, HTTPException

from backend.services.ai_service import fetch_ai_logs, generate_contextual_ai_conversation
from backend.dependencies.db import get_db, get_db_session
from typing import Annotated
from pydantic import BaseModel

router = APIRouter(prefix="/ai_logs", tags=["AI Logs"])

# 사용자 메시지 모델
class ChatMessage(BaseModel):
    message: str

# 대화 내용 불러오기
@router.get("/{diary_id}")
async def get_ai_logs_route(
    diary_id: int,
    db: Annotated[object, Depends(get_db)],
    # user_id: int = Depends(get_current_user)
):
    """
    특정 일기의 AI 대화 로그를 조회합니다.
    대화 내역이 없으면 초기 AI 메시지를 자동 생성합니다.
    """
    logs = fetch_ai_logs(diary_id, db)
    
    # logs를 chats 형태로 변환
    chats = []
    for log in logs:
        chats.append({
            "by": log["written_by"],
            "text": log["content"]
        })
    
    # 대화 내역이 없으면 초기 AI 메시지 생성
    if not chats:
        from backend.services.ai_service import generate_ai_response_logic
        from backend.models.diary import DiaryEntry, Photo, AIQueryLog
        
        # 일기 정보 가져오기
        db_session = get_db_session()
        try:
            diary = db_session.query(DiaryEntry).filter(DiaryEntry.id == diary_id).first()
            if diary:
                # 사진 설명들 가져오기
                photos = db_session.query(Photo).filter(Photo.diary_id == diary_id).all()
                photo_descriptions = [photo.description for photo in photos if photo.description]
                
                # 첫 번째 질문 생성 (사진 설명 기반)
                first_question, _, _ = generate_ai_response_logic(
                    diary, photo_descriptions, [], ""
                )
                
                # 초기 AI 메시지들을 DB에 저장
                initial_message = AIQueryLog(
                    diary_id=diary_id,
                    content="일기를 생성하는거 도와줄게. 질문에 대답해줘",
                    written_by="ai"
                )
                db_session.add(initial_message)
                
                first_question_log = AIQueryLog(
                    diary_id=diary_id,
                    content=first_question,
                    written_by="ai"
                )
                db_session.add(first_question_log)
                
                db_session.commit()
                
                chats = [
                    {"by": "ai", "text": "일기를 생성하는거 도와줄게. 질문에 대답해줘"},
                    {"by": "ai", "text": first_question}
                ]
        finally:
            db_session.close()
    
    return {"chats": chats}


# 사용자 대화 업로드 및 AI 응답
@router.post("/{diary_id}")
async def upload_user_message(
    diary_id: int,
    chat_input: ChatMessage,
    db: Annotated[object, Depends(get_db)],
    # user_id: int = Depends(get_current_user)
):
    """
    사용자 메시지를 업로드하고 AI 응답을 생성합니다.
    - diary_id: 일기 ID
    - message: 사용자 메시지
    - 반환: 대화 히스토리와 AI 응답
    """
    try:
        result = generate_contextual_ai_conversation(diary_id, chat_input.message)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 대화 생성 실패: {str(e)}")