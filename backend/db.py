# db.py
# 도메인 수정
import mysql.connector
from dotenv import load_dotenv
import os

if os.getenv("RAILWAY_ENVIRONMENT"):  # 배포 환경에서만 존재하는 Railway env
    load_dotenv(".env.production")
else:
    load_dotenv() 

print("📦 ENV HOST:", os.getenv("DB_HOST"))

db = mysql.connector.connect(
    host="mydiary-main.up.railway.app",
    user="root",
    password="ikuHPVzXkwJJyWBWlfiGJWOmuatObixw",
    database="railway"
)

def get_db():
    return mysql.connector.connect(
        host="mydiary-main.up.railway.app",
        user="root",
        password="ikuHPVzXkwJJyWBWlfiGJWOmuatObixw",
        database="railway"
    )