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


class PersonCreate(BaseModel):
    name: str
    relation: Optional[str] = None


class Person(PersonCreate):
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


class LocationLogCreate(BaseModel):
    address: str
    lat: float
    lng: float


class LocationLog(LocationLogCreate):
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
    people: Optional[List[PersonCreate]] = []
    queries: Optional[List[AIQueryLogCreate]] = []
    locations: Optional[List[LocationLogCreate]] = []

class DiaryUpdateSchema(BaseModel):
    text: str  # 수정할 일기 내용

class DiaryEntry(DiaryEntryCreate):
    id: int
    created_at: datetime
    updated_at: datetime

    photos: List[Photo] = []
    people: List[Person] = []
    queries: List[AIQueryLog] = []
    locations: List[LocationLog] = []

    class Config:
        from_attributes = True
