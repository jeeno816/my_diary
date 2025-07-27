from sqlmodel import SQLModel, Field, Relationship
from typing import List, Optional
from datetime import datetime

class Photo(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    diary_id: int = Field(foreign_key="diaryentry.id")
    file_path: str

class Person(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    diary_id: int = Field(foreign_key="diaryentry.id")
    name: str
    phone: str

class AIQueryLog(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    diary_id: int = Field(foreign_key="diaryentry.id")
    question: str
    answer: str

    diary: Optional["DiaryEntry"] = Relationship(back_populates="ai_logs")

class DiaryEntry(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    date: datetime
    title: str
    content: str
    mood: str
    created_at: datetime
    updated_at: datetime

    photos: List[Photo] = Relationship(back_populates="diary")
    people: List[Person] = Relationship(back_populates="diary")
    ai_logs: List[AIQueryLog] = Relationship(back_populates="diary")

Photo.diary = Relationship(back_populates="photos")
Person.diary = Relationship(back_populates="people")
AIQueryLog.diary = Relationship(back_populates="ai_logs")