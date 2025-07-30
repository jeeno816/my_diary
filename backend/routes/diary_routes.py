from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime, date
from typing import List, Optional

import firebase_admin
from firebase_admin import auth

from backend.schemas.diary import DiaryEntryCreate, DiaryUpdateSchema, DiaryEntry
from backend.services.diary_service import (
    create_diary_entry,
    get_diary_entry,
    diary_exists_by_date,
    get_diary_days_in_month,
    update_diary_content,
    delete_diary
)
from backend.services.photo_service import upload_photo_with_description

router = APIRouter(prefix="/diaries", tags=["Diary"])
auth_scheme = HTTPBearer()

# Firebase Admin SDK 초기화 확인
def ensure_firebase_initialized():
    """Firebase Admin SDK가 초기화되었는지 확인하고, 필요시 초기화합니다."""
    if not firebase_admin._apps:
        print("Firebase Admin SDK가 초기화되지 않았습니다. 초기화 시도...")
        from backend.dependencies.auth import initialize_firebase
        initialize_firebase()

# ✅ Firebase UID 추출 함수 (중복 제거용)
def get_firebase_uid(token: HTTPAuthorizationCredentials) -> str:
    try:
        # Firebase 초기화 확인
        ensure_firebase_initialized()
        
        print(f"토큰 검증 시작 (diary_routes): {token.credentials[:50]}...")
        decoded_token = auth.verify_id_token(token.credentials)
        uid = decoded_token.get("uid")
        print(f"토큰 검증 성공 (diary_routes): UID = {uid}")
        return uid
    except Exception as e:
        print(f"토큰 검증 실패 (diary_routes): {e}")
        raise HTTPException(status_code=401, detail=f"Invalid Firebase token: {str(e)}")

# ✅ 일기 생성 (사진 포함)
@router.post("/")
async def create_diary(
    date: str = Form(...),  # YYYY-MM-DD 형식
    mood: str = Form(...),  # 필수, 기분 이모지
    content: Optional[str] = Form(""),  # 선택사항, 기본값 빈 문자열
    photos: Optional[List[UploadFile]] = File(None),
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    """
    일기와 사진을 함께 생성합니다.
    - date: YYYY-MM-DD 형식 (예: 2024-01-15) - 필수
    - mood: 기분 이모지 - 필수 (예: 😊, 😄, 😔)
    - content: 일기 내용 - 선택사항 (나중에 추가 가능)
    - photos: 업로드할 사진들 (선택사항, Gemini API로 자동 설명 생성)
    """
    try:
        uid = get_firebase_uid(token)
        
        # date 문자열을 date 객체로 변환
        diary_date = datetime.strptime(date, "%Y-%m-%d").date()
        
        # 해당 날짜에 이미 일기가 있는지 확인
        if diary_exists_by_date(diary_date, uid):
            raise HTTPException(
                status_code=409, 
                detail=f"{date} 날짜에 이미 일기가 존재합니다. 다른 날짜를 선택하거나 기존 일기를 수정해주세요."
            )
        
        # content가 None이면 빈 문자열로 설정 (일기 내용은 나중에 추가)
        diary_content = content if content is not None else ""
        
        # 일기 생성
        diary_id = create_diary_entry(
            date=diary_date,
            user_id=uid,
            content=diary_content,
            mood=mood
        )
        
        # 사진 업로드 처리
        uploaded_photos = []
        if photos:
            for photo in photos:
                try:
                    photo_id, photo_url, photo_description = await upload_photo_with_description(
                        diary_id=diary_id,
                        photo=photo,
                        db=None
                    )
                    uploaded_photos.append({
                        "photo_id": photo_id,
                        "photo_url": photo_url,
                        "photo_description": photo_description
                    })
                except Exception as e:
                    print(f"사진 업로드 실패: {e}")
                    # 사진 업로드 실패해도 일기는 생성됨
        
        return {
            "diary_id": diary_id,
            "date": date,
            "content": diary_content,
            "mood": mood,
            "uploaded_photos": uploaded_photos,
            "message": "일기가 성공적으로 생성되었습니다.",
            "auto_generated": content is None or content == ""  # 자동생성 여부 표시
        }
        
    except HTTPException:
        # HTTPException은 그대로 재발생
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"날짜 형식 오류: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"일기 생성 실패: {str(e)}")

# ✅ 일기만 생성 (사진 없음)
@router.post("/text-only")
async def create_text_diary(
    date: str = Form(...),  # YYYY-MM-DD 형식
    mood: str = Form(...),  # 필수, 기분 이모지
    content: Optional[str] = Form(""),  # 선택사항, 기본값 빈 문자열
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    """
    사진 없이 텍스트 일기만 생성합니다.
    - date: YYYY-MM-DD 형식 (예: 2024-01-15) - 필수
    - mood: 기분 이모지 - 필수 (예: 😊, 😄, 😔)
    - content: 일기 내용 - 선택사항 (나중에 추가 가능)
    """
    try:
        uid = get_firebase_uid(token)
        
        # date 문자열을 date 객체로 변환
        diary_date = datetime.strptime(date, "%Y-%m-%d").date()
        
        # 해당 날짜에 이미 일기가 있는지 확인
        if diary_exists_by_date(diary_date, uid):
            raise HTTPException(
                status_code=409, 
                detail=f"{date} 날짜에 이미 일기가 존재합니다. 다른 날짜를 선택하거나 기존 일기를 수정해주세요."
            )
        
        # content가 None이면 빈 문자열로 설정 (일기 내용은 나중에 추가)
        diary_content = content if content is not None else ""
        
        # 일기 생성
        diary_id = create_diary_entry(
            date=diary_date,
            user_id=uid,
            content=diary_content,
            mood=mood
        )
        
        return {
            "diary_id": diary_id,
            "date": date,
            "content": diary_content,
            "mood": mood,
            "uploaded_photos": [],
            "message": "텍스트 일기가 성공적으로 생성되었습니다.",
            "type": "text_only"
        }
        
    except HTTPException:
        # HTTPException은 그대로 재발생
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"날짜 형식 오류: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"일기 생성 실패: {str(e)}")

# ✅ 일기 불러오기
@router.get("/{diary_id}", response_model=DiaryEntry)
def read_diary(
    diary_id: int,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    uid = get_firebase_uid(token)
    diary = get_diary_entry(diary_id)
    if not diary:
        raise HTTPException(status_code=404, detail="Diary not found")
    return diary

# ✅ 날짜 기반 일기 유무 확인
@router.get("/date/{target_date}")
def check_diary_exists(
    target_date: date,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    uid = get_firebase_uid(token)
    exists = diary_exists_by_date(target_date, uid)
    
    # 일기가 존재하면 diary_id도 함께 반환
    diary_id = None
    if exists:
        # 해당 날짜의 일기 ID 조회
        from backend.services.diary_service import get_diary_by_date
        diary = get_diary_by_date(target_date, uid)
        if diary:
            diary_id = diary.id
    
    return {
        "exists": exists,
        "diary_id": diary_id
    }

# ✅ 월별 일기 존재 여부
@router.get("/month/{year_month}")
def diary_days_by_month(
    year_month: str,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    """
    특정 월의 일기 존재 여부를 확인합니다.
    year_month: YYYY-MM 형식 (예: 2024-01)
    """
    try:
        year, month = map(int, year_month.split('-'))
        uid = get_firebase_uid(token)
        days = get_diary_days_in_month(year, month, uid)
        return {"days": days}
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid year_month format. Use YYYY-MM")

# ✅ 일기 삭제
@router.delete("/{id}")
async def delete_diary_endpoint(
    id: int,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    uid = get_firebase_uid(token)
    success = delete_diary(id=id, db=None, user_id=uid)
    if not success:
        raise HTTPException(status_code=404, detail="Diary not found or not authorized.")
    return {"message": "Diary deleted successfully"}

# ✅ 일기 내용 수정
@router.patch("/{id}")
async def update_diary_content_endpoint(
    id: int,
    body: DiaryUpdateSchema,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    uid = get_firebase_uid(token)
    success = update_diary_content(id=id, content=body.text, db=None, user_id=uid)
    if not success:
        raise HTTPException(status_code=404, detail="Diary not found or not authorized.")
    return {"message": "Diary content updated successfully"}

