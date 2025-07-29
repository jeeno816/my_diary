# import

# 대화 내용 불러오기
@router.get("/ai_logs/{diary_id}/ai_logs")
async def get_ai_logs(
    diary_id: int,
    db: Annotated[CMySQLConnection, Depends(get_db)],
    user_id: int = Depends(get_current_user)
):
    logs = fetch_ai_logs(diary_id, db)
    return {"logs": logs}

# 채팅
@router.post("/ai_logs/{diary_id}/ai_logs")
async def chat_with_ai(
    diary_id: int,
    input: ChatInputSchema,
    db: Annotated[CMySQLConnection, Depends(get_db)],
    user_id: int = Depends(get_current_user)
):
    reply = generate_ai_reply(diary_id, input, db)
    return {"reply": reply}