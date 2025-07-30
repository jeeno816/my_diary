import os
import shutil
import uuid
from fastapi import UploadFile
import mysql.connector
from dotenv import load_dotenv
from backend.services.gemini_service import analyze_photo_and_generate_description
from io import BytesIO

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

def delete_photo_by_id(diary_id: int, photo_id: int, db):
    conn = get_mysql_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM Photo WHERE id = %s AND diary_id = %s", (photo_id, diary_id))
    conn.commit()
    success = cursor.rowcount > 0
    conn.close()
    return success

async def upload_photo_with_description(diary_id: int, photo: UploadFile, db):
    # 1. 파일 저장
    filename = f"{uuid.uuid4().hex}_{photo.filename}"
    file_path = f"resources/photos/{filename}"
    url_path = f"/resources/photos/{filename}"  # 웹 접근용 URL 경로
    os.makedirs("resources/photos", exist_ok=True)
    
    # 파일을 메모리에 복사 (Gemini API 분석용)
    photo_data = await photo.read()
    
    # 파일 저장
    with open(file_path, "wb") as buffer:
        buffer.write(photo_data)
    
    # 2. Gemini API로 사진 설명 요청
    try:
        # UploadFile 객체를 다시 생성 (분석용)
        photo_for_analysis = UploadFile(
            filename=photo.filename,
            file=BytesIO(photo_data)
        )
        photo_description = await analyze_photo_and_generate_description(photo_for_analysis)
    except Exception as e:
        print(f"Gemini API 분석 실패: {e}")
        photo_description = "사진이 포함된 일기입니다."

    # 3. DB에 저장 (URL 경로 저장)
    conn = get_mysql_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO Photo (diary_id, path, description)
        VALUES (%s, %s, %s)
    """, (diary_id, url_path, photo_description))
    conn.commit()
    photo_id = cursor.lastrowid
    conn.close()
    return photo_id, url_path, photo_description