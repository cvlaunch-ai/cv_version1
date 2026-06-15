import os
import time
from datetime import datetime
from fastapi import APIRouter
from app.schemas.requests import VoiceText
from app.services.translation_service import TranslationService
from app.services.resume_service import ResumeService

from app.core.config import settings

router = APIRouter()

@router.post("/parse-and-save")
async def parse_and_save(data: VoiceText):
    try:
        # Log the received text for debugging
        print(f"\nReceived text from Flutter: {data.text}")
        
        # Translate to English if needed
        english_text = TranslationService.translate_to_english(data.text)
        print(f"Text for parsing: {english_text}")
        
        # Extract fields from the translated English text
        parsed = ResumeService.extract_fields(english_text)
        print(f"Parsed fields: {parsed}")
        
        # Save to Excel file
        os.makedirs(settings.DATABASE_DIR, exist_ok=True)
        excel_file = os.path.join(settings.DATABASE_DIR, "leads_data.xlsx")
        
        timestamp = str(datetime.now())
        
        # Row data: Name, Email, Phone, Job Role, Timestamp
        row_data = [
            parsed["name"],
            parsed["mailid"],
            parsed["phone"],
            parsed["jobrole"],
            timestamp
        ]

        try:
            from app.repositories.lead_repository import LeadRepository
            status_msg = LeadRepository.save_lead_excel(row_data, excel_file)
            return {
                "status": status_msg,
                "data": parsed
            }
        except PermissionError:
            return {
                "status": "[ERROR] FILE LOCKED. Close leads_data.xlsx!",
                "error": "File is locked"
            }
        except Exception as e:
            return {
                "status": f"[ERROR] Save Failed: {str(e)}",
                "error": str(e)
            }

    except Exception as e:
        print(f"[ERROR] Error: {str(e)}")
        return {
            "status": "[ERROR] Failed",
            "error": str(e)
        }
