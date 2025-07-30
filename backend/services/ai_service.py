import mysql.connector
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

def fetch_ai_logs(diary_id: int, db):
    conn = get_mysql_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM AIQueryLog WHERE diary_id = %s", (diary_id,))
    logs = cursor.fetchall()
    conn.close()
    return logs

def generate_ai_reply(diary_id: int, input, db):
    conn = get_mysql_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO AIQueryLog (diary_id, content, written_by)
        VALUES (%s, %s, %s)
    """, (diary_id, input.content, "user"))
    conn.commit()
    conn.close()
    return "AI 응답이 생성되었습니다."