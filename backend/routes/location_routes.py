from models.diary import DiaryEntry
from fastapi import APIRouter, Depends
from schemas.diary import LocationLogCreate
from services.location_service import create_location, remove_location
from dependencies.db import get_db
from typing import Annotated
from mysql.connector.connection_cext import CMySQLConnection
from dependencies.auth import get_current_user

router = APIRouter(prefix="/location_logs", tags=["Location Logs"])

# 위치 기록 등록
@router.post("/location_logs/{diary_id}/location_logs")
async def add_location(
    diary_id: int,
    location: LocationLogCreate,
    db: Annotated[CMySQLConnection, Depends(get_db)],
    user_id: int = Depends(get_current_user)
):
    location_id = create_location(diary_id, location, db)
    return {"location_id": location_id}

# 위치 기록 삭제
@router.post("/location_logs/{diary_id}/location_logs/{id}")
async def delete_location(
    diary_id: int,
    id: int,
    db: Annotated[CMySQLConnection, Depends(get_db)],
    user_id: int = Depends(get_current_user)
):
    success = remove_location(diary_id, id, db)
    return {"is_successful": success}