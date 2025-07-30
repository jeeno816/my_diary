from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
# from backend.dependencies.auth import get_current_user
from backend.dependencies.db import get_db
from backend.services.photo_service import upload_photo_with_description
from fastapi.responses import JSONResponse
from typing import Annotated
import mysql.connector

router = APIRouter(prefix="/photos", tags=["Photos"])

#사진 업로드
@router.post("/{diary_id}/photos")
async def upload_photo(
    diary_id: int,
    db: Annotated[mysql.connector.connection_cext.CMySQLConnection, Depends(get_db)],
    # user_id: int = Depends(get_current_user),
    photo: UploadFile = File(...)
):
    try:
        photo_id, photo_src, photo_description = await upload_photo_with_description(diary_id, photo, db)
        return {
            "photo_id": photo_id,
            "photo_src": photo_src,
            "photo_description": photo_description
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

#사진 삭제    
@router.delete("/{diary_id}/photos/{photo_id}")
async def delete_photo(
    diary_id: int,
    photo_id: int,
    db: Annotated[mysql.connector.connection_cext.CMySQLConnection, Depends(get_db)],
    # user_id: int = Depends(get_current_user)
):
    from backend.services.photo_service import delete_photo_by_id
    success = delete_photo_by_id(diary_id, photo_id, db)
    return { "is_successful": success }