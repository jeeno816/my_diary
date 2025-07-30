import mysql.connector
from backend.db import get_db

def create_person(diary_id: int, name: str, relation: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO Person (diary_id, name, relation)
        VALUES (%s, %s, %s)
    """, (diary_id, name, relation))
    conn.commit()
    return {"is_successful": True, "person_id": cursor.lastrowid}

def delete_person(diary_id: int, person_id: int):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM Person WHERE id = %s AND diary_id = %s", (person_id, diary_id))
    conn.commit()
    return {"is_successful": True}