from fastapi import APIRouter, HTTPException, Request, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime

from backend.db import db, get_db  # get_db가 따로 정의되어 있어야 함
from backend.schemas.diary import DiaryCreate
from backend.models import DiaryEntry, Photo, Person, AIQueryLog

router = APIRouter(prefix="/diaries", tags=["diary"])

# 일기 업로드
@router.post("/diaries/")
def create_diary(entry: DiaryCreate, db: Session = Depends(get_db)):
    diary = DiaryEntry(
        date=entry.date,
        content=entry.content,
        mood=entry.mood,
        created_at=datetime.now(),
        updated_at=datetime.now()
    )
    db.add(diary)
    db.commit()
    db.refresh(diary)

    # 사진 저장
    for path in entry.photos:
        photo = Photo(diary_id=diary.id, file_path=path)
        db.add(photo)

    # 사람 저장
    for person in entry.people:
        db.add(Person(diary_id=diary.id, name=person['name'], phone=person['phone']))

    # AI 질문/답변 저장
    for q in entry.questions:
        db.add(AIQueryLog(diary_id=diary.id, question=q['question'], answer=q['answer']))

    db.commit()
    return {"message": "일기 업로드 완료", "diary_id": diary.id}

# 일기 정보 불러오기
@router.get("/diaries/{diary_id}")
async def get_diary(diary_id: int):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM DiaryEntry WHERE id = %s", (diary_id,))
    diary = cursor.fetchone()
    if not diary:
        raise HTTPException(status_code=404, detail="Diary not found")

    # 사진
    cursor.execute("SELECT * FROM Photo WHERE diary_id = %s", (diary_id,))
    diary["photos"] = cursor.fetchall()

    # 사람
    cursor.execute("SELECT * FROM Person WHERE diary_id = %s", (diary_id,))
    diary["people"] = cursor.fetchall()

    # AI 로그
    cursor.execute("SELECT * FROM AIQueryLog WHERE diary_id = %s", (diary_id,))
    diary["ai_logs"] = cursor.fetchall()

    return diary

# 일기 유무 확인
@router.get("/diaries/date/{date}")
async def check_diary_exists(date: str):  # "YYYY-MM-DD"
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM DiaryEntry WHERE date = %s", (date,))
    count = cursor.fetchone()[0]

    return {"date": date, "exists": count > 0}