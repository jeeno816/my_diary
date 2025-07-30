import calendar
from datetime import date
from sqlalchemy.orm import Session
from sqlalchemy import text
from backend.dependencies.db import get_db_session
from backend.models.diary import DiaryEntry, Photo, AIQueryLog

# 일기 생성
def create_diary_entry(date: date, user_id: str, content: str = "", mood: str = "") -> int:
    db = get_db_session()
    try:
        diary = DiaryEntry(
            date=date,
            user_id=user_id,
            content=content,
            mood=mood
        )
        db.add(diary)
        db.commit()
        db.refresh(diary)
        print(f"✅ 일기 생성 성공! ID: {diary.id}")
        return diary.id
    except Exception as e:
        print(f"❌ 일기 생성 실패: {e}")
        db.rollback()
        return 0
    finally:
        db.close()


# 일기 불러오기
def get_diary_entry(diary_id: int):
    db = get_db_session()
    try:
        diary = db.query(DiaryEntry).filter(DiaryEntry.id == diary_id).first()
        if not diary:
            return None
        
        # 관계 데이터 로드
        diary.photos = db.query(Photo).filter(Photo.diary_id == diary_id).all()
        diary.queries = db.query(AIQueryLog).filter(AIQueryLog.diary_id == diary_id).all()
        
        return diary
    finally:
        db.close()


# 날짜 기반 일기 유무 확인
def diary_exists_by_date(target_date: date, user_id: str) -> bool:
    db = get_db_session()
    try:
        count = db.query(DiaryEntry).filter(
            DiaryEntry.date == target_date,
            DiaryEntry.user_id == user_id
        ).count()
        return count > 0
    finally:
        db.close()


# 날짜로 일기 조회
def get_diary_by_date(target_date: date, user_id: str):
    db = get_db_session()
    try:
        diary = db.query(DiaryEntry).filter(
            DiaryEntry.date == target_date,
            DiaryEntry.user_id == user_id
        ).first()
        return diary
    finally:
        db.close()


# 특정 달의 일기 존재 여부 및 대표 이미지
def get_diary_days_in_month(year: int, month: int, user_id: str):
    db = get_db_session()
    try:
        # 해당 월의 일기들 조회
        entries = db.query(DiaryEntry).filter(
            DiaryEntry.user_id == user_id,
            text("YEAR(date) = :year AND MONTH(date) = :month")
        ).params(year=year, month=month).all()
        
        # 썸네일 정보와 diary_id 포함하여 조회
        diary_map = {}
        for entry in entries:
            # 각 일기의 첫 번째 사진을 썸네일로 사용
            thumbnail = db.query(Photo.path).filter(
                Photo.diary_id == entry.id
            ).first()
            diary_map[entry.date.day] = {
                "thumbnail": thumbnail[0] if thumbnail else None,
                "diary_id": entry.id
            }
        
        _, last_day = calendar.monthrange(year, month)
        result = []

        for day in range(1, last_day + 1):
            day_info = diary_map.get(day)
            result.append({
                "day": day,
                "has_diary": day in diary_map,
                "thumbnail": day_info["thumbnail"] if day_info else None,
                "diary_id": day_info["diary_id"] if day_info else None
            })

        return result
    finally:
        db.close()


# 일기 내용 수정
def update_diary_content(id: int, content: str, db, user_id: str) -> bool:
    db_session = get_db_session()
    try:
        diary = db_session.query(DiaryEntry).filter(
            DiaryEntry.id == id,
            DiaryEntry.user_id == user_id
        ).first()
        
        if diary:
            diary.content = content
            db_session.commit()
            return True
        return False
    except Exception as e:
        print(f"❌ 일기 수정 실패: {e}")
        db_session.rollback()
        return False
    finally:
        db_session.close()


# 일기 삭제
def delete_diary(id: int, db, user_id: str) -> bool:
    db_session = get_db_session()
    try:
        # 일기 조회
        diary = db_session.query(DiaryEntry).filter(
            DiaryEntry.id == id,
            DiaryEntry.user_id == user_id
        ).first()
        
        if not diary:
            print(f"일기 {id}를 찾을 수 없거나 삭제할 권한이 없습니다.")
            return False
        
        # CASCADE 설정으로 인해 관련 데이터는 자동 삭제됨
        db_session.delete(diary)
        db_session.commit()
        print(f"일기 {id}와 관련 데이터가 성공적으로 삭제되었습니다.")
        return True
        
    except Exception as e:
        print(f"❌ 일기 삭제 실패: {e}")
        db_session.rollback()
        return False
    finally:
        db_session.close()
