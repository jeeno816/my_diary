# schemas/diary.py
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class DiaryCreate(BaseModel):
    date: datetime
    content: str
    mood: Optional[str] = None
    photos: Optional[List[str]] = []
    people: Optional[List[dict]] = []  # [{'name': '지수', 'phone': '010...'}]
    questions: List[dict] = []  # [{'question': '...', 'answer': '...'}]
