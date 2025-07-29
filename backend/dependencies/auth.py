from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from firebase_admin import auth
import firebase_admin
from firebase_admin import credentials

# Firebase Admin SDK 초기화
if not firebase_admin._apps:
    cred = credentials.Certificate("firebase_admin_sdk.json")  # 경로는 실제 위치로
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
