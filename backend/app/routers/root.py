from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def root():
    return {"message": "[MIC] Free Whisper API - Running locally!", "status": "ready"}
