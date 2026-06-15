import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Add backend directory to PATH so Whisper finds the local ffmpeg.exe
_backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ["PATH"] = _backend_dir + os.pathsep + os.environ["PATH"]

class Settings:
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    
    # Absolute path calculations
    BACKEND_DIR: str = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    PROJECT_ROOT: str = os.path.dirname(BACKEND_DIR)
    DATABASE_DIR: str = os.path.join(PROJECT_ROOT, "database")
    
    # Use D: drive for all file operations as requested, fall back to current directory if D: is missing
    BASE_CONVERSION_DIR: str = "D:\\conversions" if os.path.exists("D:\\") else os.path.join(PROJECT_ROOT, "conversions")
    DOWNLOADS_DIR: str = os.path.join(BASE_CONVERSION_DIR, "downloads")
    
    LIBREOFFICE_PATHS: list = [
        r"C:\Program Files\LibreOffice\program\soffice.exe",
        r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
        r"D:\Program Files\LibreOffice\program\soffice.exe",
        "soffice"
    ]

settings = Settings()

# Ensure directories exist
for d in [settings.BASE_CONVERSION_DIR, settings.DOWNLOADS_DIR]:
    if not os.path.exists(d):
        os.makedirs(d, exist_ok=True)
