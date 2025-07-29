from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime, date
from sqlmodel import Session

import firebase_admin
from firebase_admin import auth

from models.diary import DiaryEntry
from schemas.diary import DiaryEntryCreate, DiaryUpdateSchema
from services.diary_service import (
    create_diary_entry,
    get_diary_entry,
    diary_exists_by_date,
    get_diary_days_in_month,
    update_diary_content as update_diary_content_service,
    delete_diary as delete_diary_service,
)
from dependencies.db import get_db_session
from dependencies.auth import get_current_user

router = APIRouter(prefix="/diaries", tags=["Diary"])
auth_scheme = HTTPBearer()

# ✅ Firebase UID 추출 함수
def get_firebase_uid(token: HTTPAuthorizationCredentials) -> str:
    try:
        decoded_token = auth.verify_id_token(token.credentials)
        return decoded_token.get("uid")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

# ✅ 일기 생성
@router.post("/")
async def create_diary(
    payload: DiaryEntryCreate,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    uid = get_firebase_uid(token)
    diary_id = create_diary_entry(payload.date, uid)
    return {"diaryId": diary_id}

# ✅ 일기 조회 (유저 확인 포함)
@router.get("/{diary_id}", response_model=DiaryEntry)
def read_diary(
    diary_id: int,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    uid = get_firebase_uid(token)
    diary = get_diary_entry(diary_id)
    if not diary or diary.user_id != uid:
        raise HTTPException(status_code=404, detail="Diary entry not found or not authorized")
    return diary

# ✅ 날짜 기반 일기 존재 여부
@router.get("/date/{target_date}")
def check_diary_exists(
    target_date: date,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    uid = get_firebase_uid(token)
    exists = diary_exists_by_date(target_date, uid)
    return {"exists": exists}

# ✅ 월별 일기 목록 + 썸네일
@router.get("/month/{year_month}")
def diary_days_by_month(
    year_month: str,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    try:
        target_date = datetime.strptime(year_month, "%Y-%m")
    except ValueError:
        raise HTTPException(status_code=400, detail="날짜 형식은 yyyy-mm 이어야 합니다.")

    uid = get_firebase_uid(token)
    result = get_diary_days_in_month(target_date.year, target_date.month, uid)
    return {"diary_days": result}

# ✅ 일기 삭제
@router.delete("/{id}")
async def delete_diary_route(
    id: int,
    db: Session = Depends(get_db_session),
    user_id: str = Depends(get_current_user)
):
    success = delete_diary_service(id=id, db=db, user_id=user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Diary not found or not authorized.")
    return {"is_successful": True}

# ✅ 일기 내용 수정
@router.patch("/{id}")
async def update_diary_content_route(
    id: int,
    body: DiaryUpdateSchema,
    db: Session = Depends(get_db_session),
    user_id: str = Depends(get_current_user)
):
    success = update_diary_content_service(id=id, content=body.text, db=db, user_id=user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Diary not found or not authorized.")
    return {"is_successful": True}

