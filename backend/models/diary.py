from sqlalchemy import Column, Integer, String, Text, Date, DateTime, Enum, Float, ForeignKey
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime

Base = declarative_base()

class DiaryEntry(Base):
    __tablename__ = "DiaryEntry"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(128), nullable=False)
    date = Column(Date)
    content = Column(Text)
    mood = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    photos = relationship("Photo", back_populates="diary", cascade="all, delete-orphan")
    queries = relationship("AIQueryLog", back_populates="diary", cascade="all, delete-orphan")
    model_config = {
        "from_attributes": True  # ✅ Pydantic v2 호환
    }


class Photo(Base):
    __tablename__ = "Photo"

    id = Column(Integer, primary_key=True, autoincrement=True)
    diary_id = Column(Integer, ForeignKey("DiaryEntry.id"))
    path = Column(String(255))
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    diary = relationship("DiaryEntry", back_populates="photos")
    model_config = {
        "from_attributes": True  # ✅ Pydantic v2 호환
    }







class AIQueryLog(Base):
    __tablename__ = "AIQueryLog"

    id = Column(Integer, primary_key=True, autoincrement=True)
    diary_id = Column(Integer, ForeignKey("DiaryEntry.id"))
    content = Column(Text)
    written_by = Column(Enum("user", "ai", name="written_by_enum"))
    created_at = Column(DateTime, default=datetime.utcnow)

    diary = relationship("DiaryEntry", back_populates="queries")
    model_config = {
        "from_attributes": True  # ✅ Pydantic v2 호환
    }

