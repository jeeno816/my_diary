from fastapi import FastAPI
from backend.db import get_db
from routes.diary_routes import router as diary_router

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