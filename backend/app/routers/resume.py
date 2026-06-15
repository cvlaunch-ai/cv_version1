import os
from fastapi import APIRouter, Body
from fastapi.responses import JSONResponse
import google.generativeai as genai

from app.schemas.requests import GenerateRequest, TargetedResumeRequest
from app.services.translation_service import TranslationService
from app.services.resume_service import ResumeService
from app.services.pdf_service import PDFService

router = APIRouter()

@router.post("/generate-resume-pdf")
async def generate_resume_pdf(req: GenerateRequest):
    """
    Download gateway: Ensures 1:1 match with UI content.
    """
    try:
        # Normalize text for checking
        low_text = req.text.lower()
        
        # If it looks like our structured UI output, use LITERAL PARSING
        if "|" in req.text and ("professional summary" in low_text or "summary" in low_text):
            print("[INFO] Download Clicked: Using Literal Sync.")
            parsed = ResumeService.parse_formatted_resume(req.text)
            
            # Map EXACTLY to what Template 45 expects
            final_data = {
                "name": parsed.get("name") or req.name,
                "full_name": parsed.get("name") or req.name,
                "phone": parsed.get("phone") or req.phone,
                "email": parsed.get("email") or req.email,
                "location": parsed.get("location") or "India",
                "summary": parsed.get("summary"),
                "education": parsed.get("education"),
                "responsibilities": parsed.get("responsibilities"),
                "projects": parsed.get("projects"),
                "skills": parsed.get("skills"),
                "certifications": parsed.get("certifications")
            }
            
            if req.template_id == "template_45":
                return PDFService.create_modern_resume_response(final_data, "resume.pdf")
            else:
                return PDFService.create_classic_pdf_response(final_data)

        # AI Generation Path (for voice commands)
        ai_data = ResumeService.generate_content_ai(req.text, "resume")
        final_data = ResumeService.build_resume_data(ai_data if ai_data else {})
        # Merge request metadata if AI missed it
        if not final_data.get("full_name"): 
            final_data["full_name"] = req.name
        
        if req.template_id == "template_45":
            return PDFService.create_modern_resume_response(final_data, "resume.pdf")
        else:
            return PDFService.create_classic_pdf_response(final_data)

    except Exception as e:
        import traceback
        print(f"[ERROR] PDF ERROR: {traceback.format_exc()}")
        return JSONResponse(status_code=500, content={"error": str(e), "detail": traceback.format_exc()})


@router.post("/download-resume")
async def download_resume(data: dict = Body(...)):
    raw_text = data.get('text', '')
    english_text = TranslationService.translate_to_english(raw_text)
    resume = (
        "--- Resume ---\n\n"
        f"Personal Statement:\n{english_text}\n\n"
        "Experience:\n- ... (add your experience here)\n\n"
        "Education:\n- ... (add your education here)\n\n"
        "Skills:\n- ... (add your skills here)\n\n"
        "References available upon request."
    )
    return PDFService.create_text_file_response(resume, 'resume.txt')


@router.post("/chat-resume")
async def chat_resume(data: dict = Body(...)):
    """
    Conversational endpoint for the 'Write to Resume' chat mode.
    Receives user message + chat history, returns only an AI follow-up question/message.
    Does NOT generate the resume — that is triggered separately.
    """
    user_message = data.get('message', '')
    history = data.get('history', [])  # List of {role, text}

    # Build conversation string for the AI
    history_str = "\n".join([f"{m['role'].upper()}: {m['text']}" for m in history])

    system_prompt = (
        "You are a friendly, professional AI Resume Assistant. "
        "The user is providing information for their resume. "
        "Your ONLY job is to acknowledge their input enthusiastically and tell them you are updating their live resume preview. "
        "Do NOT ask any follow-up questions. "
        "Keep your response to 1-2 short, encouraging sentences. "
        "Example: 'Got it! I've updated your resume with these details on the right.' or 'Perfect, adding that to your professional summary now!'"
    )

    prompt = f"{system_prompt}\n\nConversation so far:\n{history_str}\nUSER: {user_message}\nAI:"

    # Try Gemini first (free)
    try:
        from app.core.config import settings
        if settings.GEMINI_API_KEY:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            gemini_model = genai.GenerativeModel('gemini-flash-latest')
            response = gemini_model.generate_content(prompt)
            ai_reply = response.text.strip()
            ready = "[READY_TO_GENERATE]" in ai_reply
            ai_reply = ai_reply.replace("[READY_TO_GENERATE]", "").strip()
            return {"message": ai_reply, "ready": ready}
    except Exception as e:
        print(f"[chat-resume] Gemini error: {e}")

    # Fallback: Mistral
    mistral_api_key = os.environ.get("MISTRAL_API_KEY", "ZVzUQWNuusFD28EPJZia3E6ecLrgC1Em")
    if mistral_api_key:
        try:
            from mistralai import Mistral
            client = Mistral(api_key=mistral_api_key)
            chat_response = client.chat.complete(
                model="mistral-small-latest",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Conversation so far:\n{history_str}\nUSER: {user_message}"}
                ]
            )
            ai_reply = chat_response.choices[0].message.content.strip()
            ready = "[READY_TO_GENERATE]" in ai_reply
            ai_reply = ai_reply.replace("[READY_TO_GENERATE]", "").strip()
            return {"message": ai_reply, "ready": ready}
        except Exception as e:
            print(f"[chat-resume] Mistral error: {e}")

    # Final fallback
    return {
        "message": "Got it! Could you tell me more about your skills and technologies you work with?",
        "ready": False
    }


@router.post("/generate-resume-json")
async def generate_resume_json(data: dict = Body(...)):
    raw_text = data.get('text', '')
    english_text = TranslationService.translate_to_english(raw_text)
    
    lines = [l.strip() for l in english_text.split('\n') if l.strip()]
    has_pipes = False
    for i in range(min(5, len(lines))):
        if "|" in lines[i] and len(lines[i]) > 10:
            has_pipes = True
            break
            
    if (has_pipes or "professional summary" in english_text.lower()) and len(lines) > 15:
        print("[INFO] Detected Full Formatted Resume Input. Using Direct Parsing.")
        parsed_data = ResumeService.parse_formatted_resume(english_text)
        
        if parsed_data.get("name") or parsed_data.get("education"):
             final_data = {
                "full_name": parsed_data.get("name", "Your Name"),
                "phone": parsed_data.get("phone", ""),
                "email": parsed_data.get("email", ""),
                "location": parsed_data.get("location", ""),
                "summary": parsed_data.get("summary", ""),
                "education": parsed_data.get("education", ""),
                "responsibilities": parsed_data.get("responsibilities", ""),
                "projects": parsed_data.get("projects", ""),
                "skills": parsed_data.get("skills", ""),
                "certifications": parsed_data.get("certifications", ""),
            }
             for k, v in final_data.items():
                 if str(v).strip().lower() == "none": final_data[k] = ""

             return {"resume": ResumeService.build_resume_string(final_data)}

    headers = ["education", "experience", "projects", "skills", "summary", "my projects", "work experience", "professional summary"]
    lower_text = english_text.lower()
    has_headers = any(h in lower_text for h in headers)
    
    if has_headers:
         print("[INFO] Detected Semi-Structured Resume. Parsing.")
         structured_data = ResumeService.parse_structured_resume(english_text)
         if structured_data["name"] or structured_data["education"]:
             final_data = {
                "full_name": structured_data["name"] or "Your Name",
                "phone": structured_data["phone"],
                "email": structured_data["email"],
                "location": structured_data["location"] or "",
                "summary": structured_data["summary"],
                "education": "\n".join(structured_data["education"]), 
                "responsibilities": "\n".join(structured_data["responsibilities"]),
                "projects": "\n".join(structured_data["projects"]),
                "skills": ", ".join(structured_data["skills"]),
                "certifications": "\n".join(structured_data["certifications"]),
            }
             return {"resume": ResumeService.build_resume_string(final_data)}
    
    ai_data = ResumeService.generate_content_ai(raw_text, "resume")
    
    if ai_data:
        user_data = ai_data.copy()
        
        if "professional_summary" in user_data:
            user_data["summary"] = user_data["professional_summary"]
            
        if "roles_and_responsibilities" in user_data:
            user_data["responsibilities"] = user_data["roles_and_responsibilities"]
            
        tech_skills = user_data.get("technical_skills", [])
        tools = user_data.get("tools_and_technologies", [])
        
        if isinstance(tech_skills, str): tech_skills = [tech_skills]
        if isinstance(tools, str): tools = [tools]
        
        all_skills = []
        if tech_skills: all_skills.extend(tech_skills if isinstance(tech_skills, list) else [])
        if tools: all_skills.extend(tools if isinstance(tools, list) else [])
        
        user_data["skills"] = all_skills
        
        final_data = ResumeService.build_resume_data(user_data)
        return {"resume": ResumeService.build_resume_string(final_data)}

    print("[WARN] AI Failed or Key Missing. Using Regex Fallback.")
    parsed = ResumeService.extract_fields(english_text)
    
    fallback_struct = ResumeService.parse_structured_resume(english_text)
    if fallback_struct["name"] or fallback_struct["skills"]:
         final_data = {
            "full_name": fallback_struct["name"] or parsed["name"],
            "phone": fallback_struct["phone"] or parsed["phone"],
            "email": fallback_struct["email"] or parsed["mailid"],
            "location": fallback_struct["location"] or "",
            "summary": fallback_struct["summary"],
            "education": "\n".join(fallback_struct["education"]),
            "responsibilities": "\n".join(fallback_struct["responsibilities"]),
            "projects": "\n".join(fallback_struct["projects"]),
            "skills": ", ".join(fallback_struct["skills"]),
        }
         return {"resume": ResumeService.build_resume_string(final_data)}

    user_data = {
        "name": parsed["name"],
        "email": parsed["mailid"],
        "phone": parsed["phone"],
        "location": "India", 
        "education": [], 
        "skills": [s.strip() for s in parsed.get("skills", "").split(",")],
    }
    final_data = ResumeService.build_resume_data(user_data)
    return {"resume": ResumeService.build_resume_string(final_data)}


@router.post("/generate-targeted-resume")
async def generate_targeted_resume(req: TargetedResumeRequest):
    """
    Generates a resume tailored to a specific job description.
    """
    try:
        ai_data = ResumeService.generate_targeted_resume_content(req.personal_info, req.job_description)
        return {"resume": ai_data}
    except Exception as e:
        print(f"Targeted Resume Error: {e}")
        return {"error": str(e)}
