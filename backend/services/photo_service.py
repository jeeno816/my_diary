import os
import shutil
import uuid
from fastapi import UploadFile
from backend.services.gemini_service import analyze_photo_and_generate_description
from backend.dependencies.db import get_db_session
from backend.models.diary import Photo
from io import BytesIO

def delete_photo_by_id(diary_id: int, photo_id: int, db):
    db_session = get_db_session()
    try:
        photo = db_session.query(Photo).filter(
            Photo.id == photo_id,
            Photo.diary_id == diary_id
        ).first()
        
        if photo:
            db_session.delete(photo)
            db_session.commit()
            return True
        return False
    except Exception as e:
        print(f"❌ 사진 삭제 실패: {e}")
        db_session.rollback()
        return False
    finally:
        db_session.close()

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
    db_session = get_db_session()
    try:
        photo = Photo(
            diary_id=diary_id,
            path=url_path,
            description=photo_description
        )
        db_session.add(photo)
        db_session.commit()
        db_session.refresh(photo)
        return photo.id, url_path, photo_description
    except Exception as e:
        print(f"❌ 사진 DB 저장 실패: {e}")
        db_session.rollback()
        raise
    finally:
        db_session.close()