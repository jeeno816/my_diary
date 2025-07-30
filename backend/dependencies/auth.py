import os
import json
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from firebase_admin import auth
import firebase_admin
from firebase_admin import credentials

# Firebase Admin SDK 초기화
if not firebase_admin._apps:
    # 환경변수에서 Firebase Admin SDK JSON 로드
    firebase_admin_sdk_json = os.getenv('FIREBASE_ADMIN_SDK_JSON')
    
    if firebase_admin_sdk_json:
        # 환경변수에서 JSON 문자열을 파싱
        cred_dict = json.loads(firebase_admin_sdk_json)
        cred = credentials.Certificate(cred_dict)
    else:
        # 로컬 개발용 (파일에서 로드)
        try:
            cred = credentials.Certificate("backend/firebase_admin_sdk.json")
        except FileNotFoundError:
            # 파일이 없으면 기본값으로 초기화 (개발용)
            cred = credentials.Certificate("backend/my-diary-59119-firebase-adminsdk-fbsvc-cf7f138946.json")
    
    firebase_admin.initialize_app(cred)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

class User(BaseModel):
    uid: str

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    try:
        decoded_token = auth.verify_id_token(token)
        return User(uid=decoded_token["uid"])
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase ID token"
        )
