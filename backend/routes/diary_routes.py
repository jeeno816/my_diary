from fastapi import APIRouter, HTTPException
from datetime import datetime

from backend.db import get_db
from backend.schemas.diary import DiaryCreate

router = APIRouter(prefix="/diaries", tags=["diary"])

# 일기 업로드
@router.post("/")
def create_diary(entry: DiaryCreate):
    conn = get_db()
    cursor = conn.cursor()

    # DiaryEntry 저장
    cursor.execute(
        "INSERT INTO DiaryEntry (date, content, mood, created_at, updated_at) VALUES (%s, %s, %s, NOW(), NOW())",
        (entry.date, entry.content, entry.mood)
    )
    diary_id = cursor.lastrowid

    # Photo 저장
    for path in entry.photos:
        cursor.execute(
            "INSERT INTO Photo (diary_id, file_path) VALUES (%s, %s)",
            (diary_id, path)
        )

    # Person 저장
    for person in entry.people:
        cursor.execute(
            "INSERT INTO Person (diary_id, name, phone) VALUES (%s, %s, %s)",
            (diary_id, person["name"], person["phone"])
        )

    # AIQueryLog 저장
    for q in entry.questions:
        cursor.execute(
            "INSERT INTO AIQueryLog (diary_id, question, answer) VALUES (%s, %s, %s)",
            (diary_id, q["question"], q["answer"])
        )

    conn.commit()
    return {"message": "일기 업로드 완료", "diary_id": diary_id}


# 일기 상세 조회
@router.get("/{diary_id}")
def get_diary(diary_id: int):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    # DiaryEntry 조회
    cursor.execute("SELECT * FROM DiaryEntry WHERE id = %s", (diary_id,))
    diary = cursor.fetchone()
    if not diary:
        raise HTTPException(status_code=404, detail="Diary not found")

    # 사진 조회
    cursor.execute("SELECT * FROM Photo WHERE diary_id = %s", (diary_id,))
    diary["photos"] = cursor.fetchall()

    # 사람 조회
    cursor.execute("SELECT * FROM Person WHERE diary_id = %s", (diary_id,))
    diary["people"] = cursor.fetchall()

    # AI 질문/답변 조회
    cursor.execute("SELECT * FROM AIQueryLog WHERE diary_id = %s", (diary_id,))
    diary["ai_logs"] = cursor.fetchall()

    return diary


# 특정 날짜 일기 존재 여부 확인
@router.get("/date/{date}")
def check_diary_exists(date: str):  # "YYYY-MM-DD"
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM DiaryEntry WHERE date = %s", (date,))
    count = cursor.fetchone()[0]

    return {"date": date, "exists": count > 0}
