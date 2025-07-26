# main.py
from fastapi import FastAPI
import mysql.connector
from routes.diary_routes import router as diary_router
from routes.photo_routes import router as photo_router
from routes.person_routes import router as person_router
from routes.ai_logs_routes import router as ai_logs_router

app = FastAPI()

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Dlwldms0708@",
    database="my_diary"
)

@app.get("/")
def get_diaries():
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM DiaryEntry")
    result = cursor.fetchall()
    return result

app.include_router(diary_router)
app.include_router(photo_router)
app.include_router(person_router)
app.include_router(ai_logs_router)