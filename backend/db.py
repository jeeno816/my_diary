from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import os
from dotenv import load_dotenv
from urllib.parse import urlparse

load_dotenv()

# DB_URL 환경 변수 사용
DATABASE_URL = os.getenv('DB_URL')

if not DATABASE_URL:
    raise ValueError("DB_URL 환경 변수가 설정되지 않았습니다.")

# mysql://로 시작하면 mysql+pymysql://로 변환
if DATABASE_URL.startswith('mysql://') and 'pymysql' not in DATABASE_URL:
    DATABASE_URL = DATABASE_URL.replace('mysql://', 'mysql+pymysql://', 1)

print(f"🔗 데이터베이스 연결: {DATABASE_URL}")

engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()