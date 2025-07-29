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
    people = relationship("Person", back_populates="diary", cascade="all, delete-orphan")
    queries = relationship("AIQueryLog", back_populates="diary", cascade="all, delete-orphan")
    locations = relationship("LocationLog", back_populates="diary", cascade="all, delete-orphan")


class Photo(Base):
    __tablename__ = "Photo"

    id = Column(Integer, primary_key=True, autoincrement=True)
    diary_id = Column(Integer, ForeignKey("DiaryEntry.id"))
    path = Column(String(255))
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    diary = relationship("DiaryEntry", back_populates="photos")


class Person(Base):
    __tablename__ = "Person"

    id = Column(Integer, primary_key=True, autoincrement=True)
    diary_id = Column(Integer, ForeignKey("DiaryEntry.id"))
    name = Column(String(100))
    relation = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)

    diary = relationship("DiaryEntry", back_populates="people")


class AIQueryLog(Base):
    __tablename__ = "AIQueryLog"

    id = Column(Integer, primary_key=True, autoincrement=True)
    diary_id = Column(Integer, ForeignKey("DiaryEntry.id"))
    content = Column(Text)
    written_by = Column(Enum("user", "ai", name="written_by_enum"))
    created_at = Column(DateTime, default=datetime.utcnow)

    diary = relationship("DiaryEntry", back_populates="queries")


class LocationLog(Base):
    __tablename__ = "LocationLog"

    id = Column(Integer, primary_key=True, autoincrement=True)
    diary_id = Column(Integer, ForeignKey("DiaryEntry.id"))
    address = Column(String(255))
    lat = Column(Float)
    lng = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)

    diary = relationship("DiaryEntry", back_populates="locations")
