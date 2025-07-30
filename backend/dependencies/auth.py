import os
import json
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from firebase_admin import auth
import firebase_admin
from firebase_admin import credentials

# Firebase Admin SDK 초기화
def initialize_firebase():
    """Firebase Admin SDK를 초기화합니다."""
    if not firebase_admin._apps:
        try:
            # 환경변수에서 Firebase Admin SDK JSON 로드
            firebase_admin_sdk_json = os.getenv('FIREBASE_ADMIN_SDK_JSON')
            
            if firebase_admin_sdk_json:
                # 환경변수에서 JSON 문자열을 파싱
                print("Firebase Admin SDK 초기화: 환경변수에서 로드")
                cred_dict = json.loads(firebase_admin_sdk_json)
                cred = credentials.Certificate(cred_dict)
            else:
                # 로컬 개발용 (파일에서 로드)
                print("Firebase Admin SDK 초기화: 파일에서 로드")
                
                # 여러 가능한 경로 시도
                possible_paths = [
                    "firebase_admin_sdk.json",
                    "my-diary-59119-firebase-adminsdk-fbsvc-cf7f138946.json",
                    "backend/firebase_admin_sdk.json",
                    "backend/my-diary-59119-firebase-adminsdk-fbsvc-cf7f138946.json",
                    "../backend/firebase_admin_sdk.json",
                    "../backend/my-diary-59119-firebase-adminsdk-fbsvc-cf7f138946.json",
                ]
                
                cred = None
                for path in possible_paths:
                    try:
                        print(f"Firebase Admin SDK 파일 시도: {path}")
                        cred = credentials.Certificate(path)
                        print(f"Firebase Admin SDK 파일 로드 성공: {path}")
                        break
                    except FileNotFoundError:
                        print(f"Firebase Admin SDK 파일 없음: {path}")
                        continue
                
                if cred is None:
                    raise FileNotFoundError("Firebase Admin SDK 파일을 찾을 수 없습니다.")
            
            firebase_admin.initialize_app(cred)
            print("Firebase Admin SDK 초기화 완료")
            
        except Exception as e:
            print(f"Firebase Admin SDK 초기화 실패: {e}")
            raise
    else:
        print("Firebase Admin SDK가 이미 초기화되어 있습니다.")

# 모듈 로드 시 초기화
initialize_firebase()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

class User(BaseModel):
    uid: str

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    try:
        # Firebase가 초기화되었는지 확인
        if not firebase_admin._apps:
            print("Firebase Admin SDK가 초기화되지 않았습니다. 재초기화 시도...")
            initialize_firebase()
        
        print(f"토큰 검증 시작: {token[:50]}...")
        decoded_token = auth.verify_id_token(token)
        print(f"토큰 검증 성공: UID = {decoded_token.get('uid')}")
        return User(uid=decoded_token["uid"])
    except Exception as e:
        print(f"토큰 검증 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Firebase ID token: {str(e)}"
        )
