from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from backend.routes.diary_routes import router as diary_router
from backend.routes.photo_routes import router as photo_router
from backend.routes.ai_routes import router as ai_router

app = FastAPI(title="My Diary API", version="1.0.0")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정적 파일 서빙 설정 (resources 폴더)
app.mount("/resources", StaticFiles(directory="resources"), name="resources")

# 라우터 등록
app.include_router(diary_router)  # prefix 제거 (diary_routes.py에서 이미 /diaries 설정됨)
app.include_router(photo_router, prefix="/photos")
app.include_router(ai_router, prefix="/ai")