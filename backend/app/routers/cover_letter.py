from datetime import datetime
from fastapi import APIRouter, Body
from reportlab.platypus import Paragraph, Spacer

from app.schemas.requests import GenerateRequest
from app.services.translation_service import TranslationService
from app.services.resume_service import ResumeService
from app.services.pdf_service import PDFService

router = APIRouter()

@router.post("/generate-cover-letter-pdf")
async def generate_cover_letter_pdf(req: GenerateRequest):
    """Generate a cover letter using a standard Professional Template (AI Enhanced)."""
    
    # Try AI (Gemini or OpenAI/Mistral) first
    ai_data = ResumeService.generate_content_ai(req.text, "cover_letter")
    
    if ai_data:
        name = ai_data.get("name", req.name or "Your Name")
        email = ai_data.get("email", req.email or "")
        phone = ai_data.get("phone", req.phone or "")
        jobrole = ai_data.get("jobrole", req.jobrole or "Candidate")
        body_content = ai_data.get("body", req.text)
    else:
        # Fallback to local parsing
        if not req.name or not req.email:
             english_text = TranslationService.translate_to_english(req.text)
             parsed = ResumeService.extract_fields(english_text)
             if not req.name: req.name = parsed.get("name", "Your Name")
             if not req.email: req.email = parsed.get("mailid", "")
             if not req.phone: req.phone = parsed.get("phone", "")
             if not req.jobrole: req.jobrole = parsed.get("jobrole", "Candidate")
        
        name = req.name
        email = req.email
        phone = req.phone
        jobrole = req.jobrole
        # Default simple body
        body_content = (
            f"I am writing to express my enthusiastic interest in the {jobrole} position. "
            f"\n\n{req.text}\n\n"
            "Thank you for your time and consideration."
        )
    
    styles = PDFService.get_styles()
    story = []

    # --- HEADER ---
    story.append(Paragraph(name, styles['HeaderName']))
    contact_info = f"{email} | {phone}"
    story.append(Paragraph(contact_info, styles['HeaderContact']))
    
    story.append(Spacer(1, 25))
    
    # --- DATE & RECIPIENT ---
    date_str = datetime.now().strftime("%B %d, %Y")
    story.append(Paragraph(date_str, styles['Normal']))
    story.append(Spacer(1, 15))
    
    story.append(Paragraph("Hiring Manager", styles['Normal']))
    story.append(Paragraph("Recruitment Team", styles['Normal']))
    story.append(Spacer(1, 15))
    
    # --- SALUTATION ---
    story.append(Paragraph("Dear Hiring Manager,", styles['Normal']))
    story.append(Spacer(1, 10))
    
    # --- BODY ---
    for para in body_content.split('\n\n'):
        if para.strip():
            story.append(Paragraph(para.strip(), styles['Justify']))
            story.append(Spacer(1, 8))
            
    story.append(Spacer(1, 15))
    
    # --- SIGN OFF ---
    story.append(Paragraph("Sincerely,", styles['Normal']))
    story.append(Spacer(1, 20)) # Space for signature
    story.append(Paragraph(name, styles['Normal']))
    if email:
        story.append(Paragraph(f"Email: {email}", styles['Normal']))
    if phone:
        story.append(Paragraph(f"Phone: {phone}", styles['Normal']))
    
    return PDFService.create_platypus_pdf_response(story, 'cover_letter.pdf')


@router.post("/download-cover-letter")
async def download_cover_letter(data: dict = Body(...)):
    raw_text = data.get('text', '')
    english_text = TranslationService.translate_to_english(raw_text)
    cover_letter = (
        "Dear Hiring Manager,\n\n"
        f"I am excited to apply for the position. {english_text}\n\n"
        "Sincerely,\nYour Name"
    )
    return PDFService.create_text_file_response(cover_letter, 'cover_letter.txt')


@router.post("/generate-cover-letter-json")
async def generate_cover_letter_json(data: dict = Body(...)):
    raw_text = data.get('text', '')
    
    # Use AI for generation
    ai_data = ResumeService.generate_content_ai(raw_text, "cover_letter")
    
    if ai_data:
        name = ai_data.get("name", "Your Name")
        body = ai_data.get("body", "I am writing to express my interest...")
        
        cover_letter = (
            "Dear Hiring Manager,\n\n"
            f"{body}\n\n"
            f"Sincerely,\n{name}"
        )
    else:
        # [FALLBACK]: Use Robust Parsing
        local_data = ResumeService.parse_cover_letter_locally(raw_text)
        name = local_data["name"]
        
        cover_letter = (
            "Dear Hiring Manager,\n\n"
            f"{local_data['body']}\n\n"
            f"Sincerely,\n{name}\n{local_data['email']}\n{local_data['phone']}"
        )
        
    return {"cover_letter": cover_letter}
