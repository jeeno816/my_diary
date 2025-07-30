import mysql.connector
import calendar
from datetime import date
import os
from dotenv import load_dotenv

load_dotenv()

def get_mysql_connection():
    """MySQL 데이터베이스 연결을 반환합니다."""
    return mysql.connector.connect(
        host=os.getenv('DB_HOST'),
        port=int(os.getenv('DB_PORT', 3306)),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASS'),
        database=os.getenv('DB_NAME')
    )

# 일기 생성
def create_diary_entry(date: date, user_id: str, content: str = "", mood: str = "") -> int:
    conn = get_mysql_connection()
    cursor = conn.cursor()
    sql = """
        INSERT INTO DiaryEntry (date, content, mood, user_id, created_at, updated_at)
        VALUES (%s, %s, %s, %s, NOW(), NOW())
    """
    cursor.execute(sql, (date, content, mood, user_id))
    conn.commit()
    diary_id = cursor.lastrowid
    conn.close()
    return diary_id


# 일기 불러오기
def get_diary_entry(diary_id: int):
    conn = get_mysql_connection()
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
    conn = get_mysql_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM DiaryEntry WHERE date = %s AND user_id = %s", (target_date, user_id))
    count = cursor.fetchone()[0]
    conn.close()
    return count > 0


# 특정 달의 일기 존재 여부 및 대표 이미지
def get_diary_days_in_month(year: int, month: int, user_id: str):
    conn = get_mysql_connection()
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


# 일기 내용 수정
def update_diary_content(id: int, content: str, db, user_id: str) -> bool:
    conn = get_mysql_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE DiaryEntry 
        SET content = %s, updated_at = NOW() 
        WHERE id = %s AND user_id = %s
    """, (content, id, user_id))
    conn.commit()
    success = cursor.rowcount > 0
    conn.close()
    return success


# 일기 삭제
def delete_diary(id: int, db, user_id: str) -> bool:
    conn = get_mysql_connection()
    cursor = conn.cursor()
    
    try:
        # 트랜잭션 시작
        conn.start_transaction()
        
        # 1. 연결된 사진들 먼저 삭제
        cursor.execute("DELETE FROM Photo WHERE diary_id = %s", (id,))
        deleted_photos = cursor.rowcount
        print(f"삭제된 사진 수: {deleted_photos}")
        
        # 2. 연결된 사람들 삭제
        cursor.execute("DELETE FROM Person WHERE diary_id = %s", (id,))
        deleted_people = cursor.rowcount
        print(f"삭제된 사람 수: {deleted_people}")
        
        # 3. 연결된 AI 쿼리 로그 삭제
        cursor.execute("DELETE FROM AIQueryLog WHERE diary_id = %s", (id,))
        deleted_queries = cursor.rowcount
        print(f"삭제된 AI 쿼리 수: {deleted_queries}")
        
        # 4. 연결된 위치 로그 삭제
        cursor.execute("DELETE FROM LocationLog WHERE diary_id = %s", (id,))
        deleted_locations = cursor.rowcount
        print(f"삭제된 위치 로그 수: {deleted_locations}")
        
        # 5. 마지막으로 일기 삭제
        cursor.execute("DELETE FROM DiaryEntry WHERE id = %s AND user_id = %s", (id, user_id))
        success = cursor.rowcount > 0
        
        if success:
            # 트랜잭션 커밋
            conn.commit()
            print(f"일기 {id}와 관련 데이터가 성공적으로 삭제되었습니다.")
        else:
            # 트랜잭션 롤백
            conn.rollback()
            print(f"일기 {id}를 찾을 수 없거나 삭제할 권한이 없습니다.")
        
        return success
        
    except Exception as e:
        # 에러 발생 시 트랜잭션 롤백
        conn.rollback()
        print(f"일기 삭제 중 에러 발생: {e}")
        return False
    finally:
        conn.close()
