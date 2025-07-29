from models.diary import DiaryEntry
from fastapi import APIRouter, Depends
from schemas.diary import PersonCreate
from services.person_service import create_person, remove_person
from dependencies.db import get_db
from typing import Annotated
from mysql.connector.connection_cext import CMySQLConnection
from dependencies.auth import get_current_user

router = APIRouter(prefix="/location_logs", tags=["Location Logs"])

# 연락처 업로드
@router.post("/people/{diary_id}/people")
async def upload_person(
    diary_id: int,
    person: PersonCreate,
    db: Annotated[CMySQLConnection, Depends(get_db)],
    user_id: int = Depends(get_current_user)
):
    person_id = create_person(diary_id, person, db)
    return {"person_id": person_id}

# 연락처 삭제
@router.delete("/people/{diary_id}/people/{id}")
async def delete_person(
    diary_id: int,
    id: int,
    db: Annotated[CMySQLConnection, Depends(get_db)],
    user_id: int = Depends(get_current_user)
):
    success = remove_person(diary_id, id, db)
    return {"is_successful": success}