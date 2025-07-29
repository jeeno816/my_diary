from db import get_db

def get_ai_logs(diary_id: int):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM AIQueryLog WHERE diary_id = %s", (diary_id,))
    return cursor.fetchall()

def insert_ai_log(diary_id: int, content: str, written_by: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO AIQueryLog (diary_id, content, written_by)
        VALUES (%s, %s, %s)
    """, (diary_id, content, written_by))
    conn.commit()
    return {"is_successful": True, "log_id": cursor.lastrowid}