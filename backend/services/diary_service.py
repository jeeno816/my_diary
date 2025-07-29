import mysql.connector
import calendar
from datetime import date
from db import get_db


# 일기 생성
def create_diary_entry(date: date, user_id: str) -> int:
    conn = get_db()
    cursor = conn.cursor()
    sql = """
        INSERT INTO DiaryEntry (date, content, mood, user_id, created_at, updated_at)
        VALUES (%s, '', '', %s, NOW(), NOW())
    """
    cursor.execute(sql, (date, user_id))
    conn.commit()
    diary_id = cursor.lastrowid
    conn.close()
    return diary_id


# 일기 불러오기
def get_diary_entry(diary_id: int):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM DiaryEntry WHERE id = %s", (diary_id,))
    diary = cursor.fetchone()
    if not diary:
        conn.close()
        return None

    cursor.execute("SELECT * FROM Photo WHERE diary_id = %s", (diary_id,))
    diary["photos"] = cursor.fetchall()

    cursor.execute("SELECT * FROM Person WHERE diary_id = %s", (diary_id,))
    diary["people"] = cursor.fetchall()

    cursor.execute("SELECT * FROM AIQueryLog WHERE diary_id = %s", (diary_id,))
    diary["queries"] = cursor.fetchall()

    cursor.execute("SELECT * FROM LocationLog WHERE diary_id = %s", (diary_id,))
    diary["locations"] = cursor.fetchall()

    conn.close()
    return diary


# 날짜 기반 일기 유무 확인
def diary_exists_by_date(target_date: date, user_id: str) -> bool:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM DiaryEntry WHERE date = %s AND user_id = %s", (target_date, user_id))
    count = cursor.fetchone()[0]
    conn.close()
    return count > 0


# 특정 달의 일기 존재 여부 및 대표 이미지
def get_diary_days_in_month(year: int, month: int, user_id: str):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT date, 
               (SELECT path FROM Photo WHERE diary_id = DiaryEntry.id LIMIT 1) as thumbnail
        FROM DiaryEntry
        WHERE YEAR(date) = %s AND MONTH(date) = %s AND user_id = %s
    """, (year, month, user_id))
    entries = cursor.fetchall()
    conn.close()

    diary_map = {entry["date"].day: entry["thumbnail"] for entry in entries}
    _, last_day = calendar.monthrange(year, month)
    result = []

    for day in range(1, last_day + 1):
        result.append({
            "day": day,
            "has_diary": day in diary_map,
            "thumbnail": diary_map.get(day)
        })

    return result
