from fastapi import FastAPI
from backend.db import get_db
from backend.routes.diary_routes import router as diary_router
from backend.routes.photo_routes import router as photo_router
from backend.routes.person_routes import router as person_router
from backend.routes.ai_routes import router as ai_router

app = FastAPI()

#루트 엔드포인트트
@app.get("/")
def root():
    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT 1")
    return {"status": "DB 연결 성공!"}

# 라우터 등록
app.include_router(diary_router)
app.include_router(photo_router)
app.include_router(person_router)
app.include_router(ai_router)