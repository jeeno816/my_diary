#!/usr/bin/env python3
"""
SQLAlchemy 모델을 기반으로 MySQL 테이블 생성 스크립트
"""

import os
import sys
from dotenv import load_dotenv

# 환경 변수 로드
load_dotenv()

# DB_URL 확인
db_url = os.getenv('DB_URL')
if not db_url:
    print("❌ DB_URL 환경 변수가 설정되지 않았습니다.")
    print("📝 .env 파일에 DB_URL을 설정해주세요.")
    sys.exit(1)

# pymysql 드라이버 확인
if db_url.startswith('mysql://') and 'pymysql' not in db_url:
    db_url = db_url.replace('mysql://', 'mysql+pymysql://', 1)

print(f"🔗 데이터베이스 연결: {db_url}")

try:
    from sqlalchemy import create_engine, text
    from models.diary import Base
    
    # 엔진 생성
    engine = create_engine(db_url, echo=True)
    
    # 연결 테스트
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("✅ 데이터베이스 연결 성공!")
    
    # 테이블 생성
    print("📋 테이블 생성 중...")
    Base.metadata.create_all(bind=engine)
    print("✅ 모든 테이블이 성공적으로 생성되었습니다!")
    
    # 생성된 테이블 확인
    with engine.connect() as conn:
        result = conn.execute(text("SHOW TABLES"))
        tables = [row[0] for row in result.fetchall()]
        print(f"📊 생성된 테이블: {', '.join(tables)}")
    
except ImportError as e:
    print(f"❌ 모듈 import 오류: {e}")
    print("📦 필요한 패키지를 설치해주세요: pip install sqlalchemy pymysql")
    sys.exit(1)
except Exception as e:
    print(f"❌ 테이블 생성 실패: {e}")
    sys.exit(1) 