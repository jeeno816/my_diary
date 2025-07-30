from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from backend.services.photo_service import upload_photo_with_description, delete_photo_by_id
from backend.services.diary_service import get_diary_entry
from fastapi.responses import JSONResponse
from typing import List, Optional
import firebase_admin
from firebase_admin import auth

router = APIRouter(prefix="/photos", tags=["Photos"])
auth_scheme = HTTPBearer()

# Firebase Admin SDK 초기화 확인
def ensure_firebase_initialized():
    """Firebase Admin SDK가 초기화되었는지 확인하고, 필요시 초기화합니다."""
    if not firebase_admin._apps:
        print("Firebase Admin SDK가 초기화되지 않았습니다. 초기화 시도...")
        from backend.dependencies.auth import initialize_firebase
        initialize_firebase()

# Firebase UID 추출 함수
def get_firebase_uid(token: HTTPAuthorizationCredentials) -> str:
    try:
        ensure_firebase_initialized()
        print(f"토큰 검증 시작 (photo_routes): {token.credentials[:50]}...")
        decoded_token = auth.verify_id_token(token.credentials)
        uid = decoded_token.get("uid")
        print(f"토큰 검증 성공 (photo_routes): UID = {uid}")
        return uid
    except Exception as e:
        print(f"토큰 검증 실패 (photo_routes): {e}")
        raise HTTPException(status_code=401, detail=f"Invalid Firebase token: {str(e)}")

# 일기 소유권 확인 함수
def verify_diary_ownership(diary_id: int, user_id: str) -> bool:
    """일기가 해당 사용자의 것인지 확인합니다."""
    try:
        diary = get_diary_entry(diary_id)
        if not diary:
            return False
        return diary.user_id == user_id  # SQLAlchemy 객체의 속성으로 접근
    except Exception as e:
        print(f"일기 소유권 확인 실패: {e}")
        return False

# 사진 업로드
@router.post("/{diary_id}/photos")
async def upload_photo(
    diary_id: int,
    photo: UploadFile = File(...),
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    """
    특정 일기에 사진을 업로드합니다.
    - diary_id: 일기 ID
    - photo: 업로드할 사진 파일
    - token: Firebase 인증 토큰
    
    사용자는 자신의 일기에만 사진을 업로드할 수 있습니다.
    """
    try:
        # 사용자 인증
        uid = get_firebase_uid(token)
        
        # 일기 소유권 확인
        if not verify_diary_ownership(diary_id, uid):
            raise HTTPException(
                status_code=403, 
                detail="이 일기에 사진을 업로드할 권한이 없습니다. 자신의 일기인지 확인해주세요."
            )
        
        # 사진 업로드 및 Gemini API 설명 생성
        photo_id, photo_url, photo_description = await upload_photo_with_description(
            diary_id=diary_id,
            photo=photo,
            db=None
        )
        
        return {
            "photo_id": photo_id,
            "photo_url": photo_url,
            "photo_description": photo_description,
            "message": "사진이 성공적으로 업로드되었습니다."
        }
        
    except HTTPException:
        # HTTPException은 그대로 재발생
        raise
    except Exception as e:
        print(f"사진 업로드 실패: {e}")
        raise HTTPException(status_code=500, detail=f"사진 업로드 실패: {str(e)}")

# 여러 사진 업로드
@router.post("/{diary_id}/photos/batch")
async def upload_multiple_photos(
    diary_id: int,
    photos: List[UploadFile] = File(...),
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    """
    특정 일기에 여러 사진을 한번에 업로드합니다.
    - diary_id: 일기 ID
    - photos: 업로드할 사진 파일들
    - token: Firebase 인증 토큰
    """
    try:
        # 사용자 인증
        uid = get_firebase_uid(token)
        
        # 일기 소유권 확인
        if not verify_diary_ownership(diary_id, uid):
            raise HTTPException(
                status_code=403, 
                detail="이 일기에 사진을 업로드할 권한이 없습니다. 자신의 일기인지 확인해주세요."
            )
        
        # 여러 사진 업로드
        uploaded_photos = []
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
                print(f"개별 사진 업로드 실패: {e}")
                # 개별 사진 실패해도 계속 진행
        
        return {
            "uploaded_photos": uploaded_photos,
            "total_count": len(uploaded_photos),
            "message": f"{len(uploaded_photos)}장의 사진이 성공적으로 업로드되었습니다."
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"다중 사진 업로드 실패: {e}")
        raise HTTPException(status_code=500, detail=f"사진 업로드 실패: {str(e)}")

# 사진 삭제    
@router.delete("/{diary_id}/photos/{photo_id}")
async def delete_photo(
    diary_id: int,
    photo_id: int,
    token: HTTPAuthorizationCredentials = Depends(auth_scheme)
):
    """
    특정 일기의 사진을 삭제합니다.
    - diary_id: 일기 ID
    - photo_id: 삭제할 사진 ID
    - token: Firebase 인증 토큰
    
    사용자는 자신의 일기의 사진만 삭제할 수 있습니다.
    """
    try:
        # 사용자 인증
        uid = get_firebase_uid(token)
        
        # 일기 소유권 확인
        if not verify_diary_ownership(diary_id, uid):
            raise HTTPException(
                status_code=403, 
                detail="이 사진을 삭제할 권한이 없습니다. 자신의 일기인지 확인해주세요."
            )
        
        # 사진 삭제
        success = delete_photo_by_id(diary_id, photo_id, None)
        
        if success:
            return {
                "message": "사진이 성공적으로 삭제되었습니다.",
                "is_successful": True
            }
        else:
            raise HTTPException(
                status_code=404, 
                detail="사진을 찾을 수 없거나 삭제할 수 없습니다."
            )
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"사진 삭제 실패: {e}")
        raise HTTPException(status_code=500, detail=f"사진 삭제 실패: {str(e)}")