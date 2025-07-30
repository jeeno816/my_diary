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

def create_person(diary_id: int, name: str, relation: str):
    conn = get_mysql_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO Person (diary_id, name, relation)
        VALUES (%s, %s, %s)
    """, (diary_id, name, relation))
    conn.commit()
    result = {"is_successful": True, "person_id": cursor.lastrowid}
    conn.close()
    return result

def delete_person(diary_id: int, person_id: int):
    conn = get_mysql_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM Person WHERE id = %s AND diary_id = %s", (person_id, diary_id))
    conn.commit()
    result = {"is_successful": True}
    conn.close()
    return result