from backend.models.diary import DiaryEntry
from fastapi import APIRouter, Depends
from backend.schemas.diary import PersonCreate
from backend.services.person_service import create_person, delete_person
from backend.dependencies.db import get_db
from typing import Annotated
from mysql.connector.connection_cext import CMySQLConnection
# from backend.dependencies.auth import get_current_user

router = APIRouter(prefix="/location_logs", tags=["Location Logs"])

# 연락처 업로드
@router.post("/people/{diary_id}/people")
async def upload_person(
    diary_id: int,
    person: PersonCreate,
    # user_id: int = Depends(get_current_user)
):
    result = create_person(diary_id, person.name, person.relation)
    return {"person_id": result["person_id"]}

# 연락처 삭제
@router.delete("/people/{diary_id}/people/{id}")
async def delete_person_route(
    diary_id: int,
    id: int,
    # user_id: int = Depends(get_current_user)
):
    result = delete_person(diary_id, id)
    return {"is_successful": result["is_successful"]}