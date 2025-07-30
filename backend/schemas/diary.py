from pydantic import BaseModel
from typing import Optional, List, Literal
from datetime import datetime, date


class PhotoCreate(BaseModel):
    path: str
    description: Optional[str] = None


class Photo(PhotoCreate):
    id: int
    diary_id: int
    created_at: datetime

    class Config:
        from_attributes = True





class AIQueryLogCreate(BaseModel):
    content: str
    written_by: Literal['user', 'ai']


class AIQueryLog(AIQueryLogCreate):
    id: int
    diary_id: int
    created_at: datetime

    class Config:
        from_attributes = True





class DiaryEntryCreate(BaseModel):
    date: date  # 필수 필드, YYYY-MM-DD 형식 (예: 2024-01-15)
    content: str  # 필수 필드, 일기 내용
    mood: Optional[str] = None  # 선택 필드, 기분 이모지 (예: 😊, 😄, 😔)
    photos: Optional[List[PhotoCreate]] = []
    queries: Optional[List[AIQueryLogCreate]] = []

class DiaryUpdateSchema(BaseModel):
    text: str  # 수정할 일기 내용

class DiaryEntry(DiaryEntryCreate):
    id: int
    created_at: datetime
    updated_at: datetime

    photos: List[Photo] = []
    queries: List[AIQueryLog] = []

    class Config:
        from_attributes = True
