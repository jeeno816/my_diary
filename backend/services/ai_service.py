from backend.dependencies.db import get_db_session
from backend.models.diary import AIQueryLog

def fetch_ai_logs(diary_id: int, db):
    db_session = get_db_session()
    try:
        logs = db_session.query(AIQueryLog).filter(
            AIQueryLog.diary_id == diary_id
        ).all()
        return logs
    finally:
        db_session.close()

def generate_ai_reply(diary_id: int, input, db):
    db_session = get_db_session()
    try:
        ai_log = AIQueryLog(
            diary_id=diary_id,
            content=input.content,
            written_by="user"
        )
        db_session.add(ai_log)
        db_session.commit()
        return "AI 응답이 생성되었습니다."
    except Exception as e:
        print(f"❌ AI 로그 저장 실패: {e}")
        db_session.rollback()
        raise
    finally:
        db_session.close()