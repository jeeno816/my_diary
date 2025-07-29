import os
import shutil
import uuid
from fastapi import UploadFile 

def delete_photo_by_id(diary_id: int, photo_id: int, db):
    cursor = db.cursor()
    cursor.execute("DELETE FROM Photo WHERE id = %s AND diary_id = %s", (photo_id, diary_id))
    db.commit()
    return cursor.rowcount > 0

async def upload_photo_with_description(diary_id: int, photo: UploadFile, db):
    # 1. 파일 저장
    filename = f"{uuid.uuid4().hex}_{photo.filename}"
    file_path = f"resources/photos/{filename}"
    os.makedirs("resources/photos", exist_ok=True)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(photo.file, buffer)

    # 2. AI로 사진 설명 요청 (여기선 mock 설명)
    photo_description = "빙수 위에 팥과 각종 토핑이 올라간 사진"  # 실제론 AI API 호출해야 함

    # 3. DB에 저장
    cursor = db.cursor()
    cursor.execute("""
        INSERT INTO Photo (diary_id, path, description)
        VALUES (%s, %s, %s)
    """, (diary_id, file_path, photo_description))
    db.commit()
    photo_id = cursor.lastrowid
    return photo_id, file_path, photo_description