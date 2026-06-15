from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import root, transcribe, lead, cover_letter, resume, pdf
from app.services.whisper_service import WhisperService

app = FastAPI(
    title="Voice Flutter Backend",
    description="Clean Architecture Refactored Backend for Resume and Cover Letter Generation.",
    version="1.0.0"
)

# Allow all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    # Pre-load Whisper model on startup to avoid delays on first request
    print("Pre-loading Whisper model on startup...")
    try:
        WhisperService.get_model()
    except Exception as e:
        print(f"Error pre-loading Whisper model: {e}")

# Include Routers directly to preserve original path paths
app.include_router(root.router)
app.include_router(transcribe.router)
app.include_router(lead.router)
app.include_router(cover_letter.router)
app.include_router(resume.router)
app.include_router(pdf.router)
