from fastapi import FastAPI
from backend.db import get_db
import os

app = FastAPI()

@app.get("/")
def root():
    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT 1")
    return {"status": "DB 연결 성공!"}