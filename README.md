# My Diary 프로젝트

## 데이터베이스 설정

이 프로젝트는 MySQL 데이터베이스를 사용하며, DB_URL을 통해 데이터베이스 연결을 설정합니다.

### DB_URL 설정

`.env` 파일에 다음과 같이 설정:

```env
# pymysql 드라이버를 명시적으로 사용 (권장)
DB_URL=mysql+pymysql://username:password@host:port/database_name

# 또는 mysql://로 시작해도 자동으로 pymysql로 변환됩니다
DB_URL=mysql://username:password@host:port/database_name
```

### 배포 환경에서 사용

배포 환경에서는 환경 변수를 직접 설정합니다:

```bash
export DB_URL="mysql+pymysql://username:password@host:port/database_name"
```

### 로컬 개발 환경 설정

1. `backend/env_example.txt` 파일을 참고하여 `.env` 파일을 생성
2. 데이터베이스 정보를 실제 값으로 수정
3. 테이블 생성:
   ```bash
   cd backend
   python create_tables.py
   ```
4. Flask 애플리케이션 실행:
   ```bash
   python main.py
   ```

## 프로젝트 구조

- `backend/`: Flask 백엔드 API (SQLAlchemy 사용)
- `frontend/`: Flutter 모바일 앱

## 주요 변경사항

- ✅ **DB_URL 전용**: 개별 환경변수 대신 DB_URL만 사용
- ✅ **SQLAlchemy ORM**: mysql.connector 대신 SQLAlchemy 사용
- ✅ **자동 드라이버 변환**: mysql:// → mysql+pymysql:// 자동 변환
- ✅ **CASCADE 삭제**: 관계 데이터 자동 삭제
- ✅ **LocationLog 제거**: 위치 기능 완전 삭제
- ✅ **Person 제거**: 연락처 기능 완전 삭제 