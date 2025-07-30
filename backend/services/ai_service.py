from backend.dependencies.db import get_db_session
from backend.models.diary import AIQueryLog
from pydantic import BaseModel
from typing import Optional


class AIResponse(BaseModel):
    answer: str
    is_edit_text: bool
    edited_text: Optional[str] = None

def fetch_ai_logs(diary_id: int, db):
    db_session = get_db_session()
    try:
        logs = db_session.query(AIQueryLog).filter(
            AIQueryLog.diary_id == diary_id
        ).order_by(AIQueryLog.created_at).all()
        
        # SQLAlchemy 객체를 딕셔너리로 변환
        result = []
        for log in logs:
            result.append({
                "id": log.id,
                "diary_id": log.diary_id,
                "content": log.content,
                "written_by": log.written_by,
                "created_at": log.created_at.isoformat() if log.created_at else None
            })
        
        return result
    finally:
        db_session.close()




def generate_contextual_ai_conversation(diary_id: int, user_message: str):
    """
    일기의 사진 설명과 기존 대화 내용을 바탕으로 AI 대화를 생성합니다.
    """
    db_session = get_db_session()
    try:
        # 1. 일기 정보 가져오기
        from backend.models.diary import DiaryEntry, Photo, AIQueryLog
        diary = db_session.query(DiaryEntry).filter(DiaryEntry.id == diary_id).first()
        if not diary:
            return {"is_successful": False, "error": "일기를 찾을 수 없습니다."}
        
        # 2. 사진 설명들 가져오기
        photos = db_session.query(Photo).filter(Photo.diary_id == diary_id).all()
        photo_descriptions = [photo.description for photo in photos if photo.description]
        
        # 3. 기존 대화 내용 가져오기
        existing_chats = db_session.query(AIQueryLog).filter(
            AIQueryLog.diary_id == diary_id
        ).order_by(AIQueryLog.created_at).all()
        
        # 4. 사용자 메시지 저장
        user_chat = AIQueryLog(
            diary_id=diary_id,
            content=user_message,
            written_by="user"
        )
        db_session.add(user_chat)
        db_session.commit()
        
        # 5. 대화 히스토리 구성
        chat_history = []
        for chat in existing_chats:
            chat_history.append({
                "by": chat.written_by,
                "text": chat.content
            })
        
        # 6. AI 응답 생성 로직
        ai_response, is_edit_request, edited_text = generate_ai_response_logic(
            diary, photo_descriptions, chat_history, user_message
        )
        
        # 7. AI 응답 저장
        ai_chat = AIQueryLog(
            diary_id=diary_id,
            content=ai_response,
            written_by="ai"
        )
        db_session.add(ai_chat)
        db_session.commit()
        
        # 8. 최종 응답 구성
        chat_history.append({"by": "user", "text": user_message})
        chat_history.append({"by": "ai", "text": ai_response})
        
        result = {
            "is_successful": True,
            "chats": chat_history,
            "is_edit_text": is_edit_request
        }
        
        if is_edit_request and edited_text:
            result["edited_text"] = edited_text
        
        return result
        
    except Exception as e:
        print(f"❌ AI 대화 생성 실패: {e}")
        db_session.rollback()
        return {"is_successful": False, "error": str(e)}
    finally:
        db_session.close()


def generate_ai_response_logic(diary, photo_descriptions, chat_history, user_message):
    """
    Gemini API를 사용한 AI 응답 생성 로직
    """
    from google import genai
    
    # Gemini API 클라이언트 생성
    client = genai.Client()
    
    # 컨텍스트 구성
    context = build_conversation_context(diary, photo_descriptions, chat_history)
    
    # Gemini 프롬프트 구성
    prompt = build_gemini_prompt(context, user_message)
    
    # 구조화된 응답을 위한 Gemini API 호출
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config={
            "response_mime_type": "application/json",
            "response_schema": AIResponse,
        },
    )
    
    # 구조화된 응답 파싱
    ai_response: AIResponse = response.parsed
    return ai_response.answer, ai_response.is_edit_text, ai_response.edited_text


def build_conversation_context(diary, photo_descriptions, chat_history):
    """대화 컨텍스트를 구성합니다."""
    context = {
        "diary_date": diary.date.strftime("%Y-%m-%d") if diary.date else "알 수 없음",
        "diary_content": diary.content or "",
        "photo_descriptions": photo_descriptions,
        "chat_history": chat_history,
        "user_response_count": len([chat for chat in chat_history if chat["by"] == "user"])
    }
    return context


def build_gemini_prompt(context, user_message):
    """Gemini API용 프롬프트를 구성합니다."""
    photo_context = ""
    if context["photo_descriptions"]:
        photo_context = f"사진 설명들: {' | '.join(context['photo_descriptions'])}\n"
    
    chat_history_text = ""
    for chat in context["chat_history"]:
        chat_history_text += f"{chat['by']}: {chat['text']}\n"
    
    prompt = f"""
당신은 친근하고 도움이 되는 AI 어시스턴트입니다. 사용자의 일기 작성을 도와주세요.

{photo_context}
일기 날짜: {context['diary_date']}
현재 일기 내용: {context['diary_content']}

기존 대화:
{chat_history_text}

사용자 메시지: {user_message}

다음 규칙을 따라 응답해주세요:

1. 사용자가 2개 질문에 답하기 전까지는 질문만 하세요.
2. 수정 요청이면 is_edit_text를 true로 설정하고 수정된 내용을 edited_text에 제공하세요.
3. 일기 생성 요청이면 is_edit_text를 true로 설정하고 생성된 일기를 edited_text에 제공하세요.
4. 일반 대화면 친근하게 응답하고 is_edit_text를 false로 설정하세요.

JSON 응답 형식:
{{
    "answer": "AI의 응답 메시지",
    "is_edit_text": true/false,
    "edited_text": "수정되거나 생성된 일기 내용 (is_edit_text가 true일 때만)"
}}

응답:
"""
    return prompt





