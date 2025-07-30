#!/usr/bin/env python3
"""
기존 LocationLog 테이블 삭제 스크립트
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
    sys.exit(1)

# pymysql 드라이버 확인
if db_url.startswith('mysql://') and 'pymysql' not in db_url:
    db_url = db_url.replace('mysql://', 'mysql+pymysql://', 1)

print(f"🔗 데이터베이스 연결: {db_url}")

try:
    from sqlalchemy import create_engine, text
    
    # 엔진 생성
    engine = create_engine(db_url, echo=True)
    
    # 연결 테스트
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("✅ 데이터베이스 연결 성공!")
    
    # LocationLog 테이블 존재 확인 및 삭제
    with engine.connect() as conn:
        # 테이블 존재 확인
        result = conn.execute(text("SHOW TABLES LIKE 'LocationLog'"))
        if result.fetchone():
            print("🗑️ LocationLog 테이블을 삭제합니다...")
            conn.execute(text("DROP TABLE LocationLog"))
            conn.commit()
            print("✅ LocationLog 테이블이 성공적으로 삭제되었습니다!")
        else:
            print("ℹ️ LocationLog 테이블이 존재하지 않습니다.")
    
    # 현재 테이블 목록 확인
    with engine.connect() as conn:
        result = conn.execute(text("SHOW TABLES"))
        tables = [row[0] for row in result.fetchall()]
        print(f"📊 현재 테이블 목록: {', '.join(tables)}")
    
except ImportError as e:
    print(f"❌ 모듈 import 오류: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ 테이블 삭제 실패: {e}")
    sys.exit(1) 