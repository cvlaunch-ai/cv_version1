import os
import re
import json
import time
from datetime import datetime
import google.generativeai as genai
import openai
from app.core.config import settings

class ResumeService:
    @staticmethod
    def parse_formatted_resume(text: str) -> dict:
        """
        100% Literal parser for UI text.
        Everything between headers is captured exactly.
        """
        lines = [l.strip() for l in text.splitlines() if l.strip()]
        if not lines: return {}
        
        data = {"name": lines[0], "phone": "", "email": "", "location": ""}
        
        # Extract contact info from line 1
        if len(lines) > 1:
            parts = [p.strip() for p in lines[1].split("|") if p.strip()]
            for p in parts:
                if "@" in p: data["email"] = p
                elif any(c.isdigit() for c in p) and len(p.replace(" ","")) > 6: 
                    data["phone"] = p
                else: data["location"] = p

        # Mapping for headers (Lowercase for matching)
        header_map = {
            "professional summary": "summary",
            "professional_summary": "summary",
            "summary": "summary",
            "education": "education",
            "roles & responsibilities": "responsibilities",
            "roles and responsibilities": "responsibilities",
            "experience": "responsibilities",
            "work experience": "responsibilities",
            "projects": "projects",
            "technologies & tools": "skills",
            "technical skills": "skills",
            "skills": "skills",
            "certifications": "certifications"
        }

        sections = {k: [] for k in ["summary", "education", "responsibilities", "projects", "skills", "certifications"]}
        current_key = "summary" 
        
        for line in lines[2:]:
            clean_l = line.lower().replace(":", "").replace("*","").strip()
            
            is_header = False
            if clean_l in header_map:
                current_key = header_map[clean_l]
                is_header = True
                
            if not is_header and current_key:
                sections[current_key].append(line)
                
        # Combine lines back to strings
        for k, v in sections.items():
            data[k] = "\n".join(v).strip()
            
        return data

    @staticmethod
    def parse_structured_resume(text: str) -> dict:
        """
        Parses a semi-structured text dump that has headers like 'Education', 'Experience'.
        This is common when users copy-paste their resume or speak it section by section.
        """
        lines = [l.strip() for l in text.split("\n") if l.strip()]
        if not lines:
            return {}

        data = {
            "name": "",
            "email": "",
            "phone": "",
            "location": "",
            "summary": "",
            "education": [],
            "projects": [],
            "skills": [],
            "responsibilities": [],
            "certifications": []
        }

        header_end_index = 0
        for i, line in enumerate(lines[:15]):
            line_lower = line.lower()
            if any(h in line_lower for h in ["professional summary", "summary", "education", "experience", "projects", "skills", "certifications"]):
                if len(line.split()) < 5: 
                     header_end_index = i
                     break
            
            if i == 0:
                name_match = re.search(r"Name:\s*(.*)", line, re.I)
                if name_match:
                    data["name"] = name_match.group(1).strip()
                else:
                    if len(line) < 50 and not any(char.isdigit() for char in line):
                        data["name"] = line
            
            email_match = re.search(r"[\w\.-]+@[\w\.-]+\.\w+", line)
            if email_match: data["email"] = email_match.group()
            
            phone_match = re.search(r"(\+?\d[\d -]{8,15})", line)
            if phone_match and len(line) < 40 and "year" not in line_lower: 
                data["phone"] = phone_match.group(1).strip()
            
            if "location:" in line_lower:
                try:
                     parts = line.split(":", 1)
                     if len(parts) > 1:
                         data["location"] = parts[1].strip()
                except: pass
            elif ("india" in line_lower or "hyderabad" in line_lower) and "@" not in line and "experience" not in line_lower:
                 data["location"] = line.strip()

        current_section = None
        buffer = []
        
        def flush_buffer(section, content_lines):
            if not content_lines: return
            content = "\n".join(content_lines)
            
            if section == "summary":
                data["summary"] = content
            elif section == "education":
                data["education"].append(content)
            elif section == "experience":
                data["responsibilities"].append(content)
            elif section == "projects":
                data["projects"].append(content)
            elif section == "skills":
                cleaned = content.replace('\n', ', ').replace('•', ',')
                data["skills"].append(cleaned)
            elif section == "certifications":
                data["certifications"].append(content)

        section_map = {
            "professional summary": "summary",
            "career summary": "summary",
            "summary": "summary",
            "education": "education",
            "qualification": "education",
            "experience": "experience",
            "work experience": "experience",
            "employment history": "experience",
            "roles & responsibilities": "experience", 
            "projects": "projects",
            "academic projects": "projects",
            "skills": "skills",
            "technical skills": "skills",
            "certifications": "certifications",
            "technologies & tools": "skills",
            "🎓 education": "education",
            "🛠️ skills": "skills",
            "📊 projects": "projects",
            "📜 certifications": "certifications",
            "💼 experience": "experience",
            "case projects": "projects"
        }

        for i in range(header_end_index, len(lines)):
            line = lines[i]
            clean_key = re.sub(r'[^\w\s]', '', line.lower()).strip()
            
            is_header = False
            mapped_section = None
            
            if clean_key in section_map:
                 is_header = True
                 mapped_section = section_map[clean_key]
            
            if not is_header and len(clean_key) < 35:
                if "summary" in clean_key: mapped_section, is_header = "summary", True
                elif "education" in clean_key or "qualification" in clean_key: mapped_section, is_header = "education", True
                elif "experience" in clean_key or "work" in clean_key or "employment" in clean_key: mapped_section, is_header = "experience", True
                elif "project" in clean_key: mapped_section, is_header = "projects", True
                elif "skill" in clean_key or "technolog" in clean_key: mapped_section, is_header = "skills", True
                elif "certif" in clean_key: mapped_section, is_header = "certifications", True
            
            if is_header:
                if current_section:
                    flush_buffer(current_section, buffer)
                current_section = mapped_section
                buffer = []
            else:
                if current_section:
                    buffer.append(line)
                elif not current_section:
                     is_contact = False
                     if "@" in line or "phone" in line.lower() or "portfolio" in line.lower() or "linkedin" in line.lower():
                         is_contact = True
                     if i == 0: is_contact = True 

                     if not is_contact:
                         current_section = "summary"
                         buffer.append(line)
        
        if current_section:
            flush_buffer(current_section, buffer)
            
        print(f"DEBUG: Parsed Sections: Summary={bool(data['summary'])}, Roles={len(data['responsibilities'])}, Edu={len(data['education'])}")

        return data

    @staticmethod
    def build_resume_string(data: dict) -> str:
        """
        Constructs the PLAIN TEXT resume string (No Markdown/JSON).
        Only renders sections that the user actually provided – NO invented/placeholder text.
        """
        name = (data.get("full_name") or data.get("name") or "").strip()
        phone = (data.get("phone") or "").strip()
        email = (data.get("email") or "").strip()
        loc = (data.get("location") or "").strip()
        summary = (data.get("summary") or "").strip()
        edu = (data.get("education") or "").strip()
        roles = (data.get("responsibilities") or "").strip()
        proj = (data.get("projects") or "").strip()
        skills = (data.get("skills") or "").strip()
        certifications = (data.get("certifications") or "").strip()

        contact_parts = [p for p in [phone, email, loc] if p]
        contact_line = " | ".join(contact_parts)
        if contact_line:
            contact_line = f"| {contact_line} |"

        lines = []
        if name:            lines.append(name)
        if contact_line:    lines.append(contact_line)
        if summary:         lines += ["", "Professional Summary", summary]
        if edu:             lines += ["", "Education", edu]
        if roles:           lines += ["", "Roles & Responsibilities", roles]
        if proj:            lines += ["", "Projects", proj]
        if skills:          lines += ["", "Technologies & Tools", skills]
        if certifications:  lines += ["", "Certifications", certifications]

        return "\n".join(lines)

    @staticmethod
    def build_resume_data(user: dict) -> dict:
        """
        Standardizes user data into the fixed resume format.
        Handles missing keys gracefully.
        """
        def clean_val(v, default=""):
            if not v: return default
            s = str(v).strip()
            if s.lower() in ["none", "null", "undefined"]: 
                return default
            if "[specify" in s.lower() or "[insert" in s.lower() or "[relevant" in s.lower() or "[year" in s.lower() or "[dates]" in s.lower():
                return default
            return s

        degree = clean_val(user.get("degree"), "Degree")
        specialization = clean_val(user.get("specialization"), "Specialization")
        
        if (degree == "Degree" or specialization == "Specialization") and user.get("education"):
            # Try to infer from first education entry
            edu_raw = ""
            if isinstance(user["education"], list) and user["education"]:
                edu_raw = str(user["education"][0])
            elif isinstance(user["education"], str):
                edu_raw = user["education"]
                
            if edu_raw:
                deg_match = re.search(r"(B\.?Tech|Bachelor|Master|Degree|Diploma|SSC|HSC|Intermediate)", edu_raw, re.I)
                if deg_match: degree = deg_match.group(1)
                spec_match = re.search(r"(?:in\s+)?([A-Za-z ]+?)\s+(?:from|at|$)", edu_raw, re.I)
                if spec_match: specialization = spec_match.group(1).strip()

        full_name = clean_val(user.get("name") or user.get("full_name"), "Candidate Name")
        phone = clean_val(user.get("phone"), "Contact Number")
        email = clean_val(user.get("email") or user.get("mailid"), "Email ID")
        location = clean_val(user.get("location"), "Location")
        
        skills = clean_val(user.get("skills") or user.get("technical_skills"))
        if isinstance(skills, list):
            skills = ", ".join(skills)
            
        summary = clean_val(user.get("summary") or user.get("professional_summary"))
        
        # Education Format
        education = ""
        if user.get("education"):
            if isinstance(user["education"], list):
                edu_items = []
                for item in user["education"]:
                    if isinstance(item, dict):
                        deg = clean_val(item.get("degree"))
                        uni = clean_val(item.get("university"))
                        yr = clean_val(item.get("year"))
                        gr = clean_val(item.get("grade"))
                        
                        parts = [deg]
                        if uni: parts.append(f"from {uni}")
                        if yr: parts.append(f"({yr})")
                        if gr: parts.append(f"- Grade: {gr}")
                        edu_items.append(" ".join(parts))
                    else:
                        edu_items.append(str(item))
                education = "\n".join([f"• {e}" for e in edu_items if e])
            else:
                education = user["education"]
                
        # Responsibilities Format
        responsibilities = ""
        exp_bullets = user.get("experience_bullets") or user.get("roles_and_responsibilities") or user.get("roles")
        if exp_bullets:
            if isinstance(exp_bullets, list):
                responsibilities = "\n".join([f"• {clean_val(b)}" for b in exp_bullets if clean_val(b)])
            else:
                responsibilities = exp_bullets
                
        # Projects Format
        projects = ""
        if user.get("projects"):
            if isinstance(user["projects"], list):
                proj_items = []
                for p in user["projects"]:
                    if isinstance(p, dict):
                        p_name = clean_val(p.get("name"), "Project")
                        p_det = p.get("details") or p.get("description")
                        if isinstance(p_det, list):
                            p_det_str = " ".join([clean_val(d) for d in p_det if clean_val(d)])
                        else:
                            p_det_str = clean_val(p_det)
                        proj_items.append(f"• {p_name}: {p_det_str}")
                    else:
                        proj_items.append(f"• {str(p)}")
                projects = "\n".join(proj_items)
            else:
                projects = user["projects"]

        certifications = ""
        certs = user.get("certifications")
        if certs:
            if isinstance(certs, list):
                certifications = "\n".join([f"• {clean_val(c)}" for c in certs if clean_val(c)])
            else:
                certifications = certs

        return {
            "full_name": full_name,
            "phone": phone,
            "email": email,
            "location": location,
            "summary": summary,
            "education": education,
            "responsibilities": responsibilities,
            "projects": projects,
            "skills": skills,
            "certifications": certifications,
        }

    @staticmethod
    def extract_fields(text: str) -> dict:
        name_match = re.search(r"(?:my name is|this is|i am|name)\s+([a-zA-Z ]{1,30})", text, re.I)
        name = ""
        if name_match:
            raw_name = name_match.group(1).strip()
            keywords = ["education", "job", "position", "applying", "role", "skill", "interest"]
            for kw in keywords:
                if f" {kw}" in raw_name.lower():
                    raw_name = raw_name.lower().split(f" {kw}")[0]
            name = raw_name.title()

        email = re.search(r"[\w\.-]+@[\w\.-]+\.\w+", text)
        phone = re.search(r"\b\d{10}\b", text)

        job_patterns = [
            r"(data analyst|analyst)",
            r"(software engineer|developer)",
            r"(python developer)",
            r"(full stack developer)",
            r"(machine learning engineer)",
            r"(student)",
            r"(ui ux designer)",
            r"(tester)"
        ]

        jobrole = None
        for pattern in job_patterns:
            match = re.search(pattern, text, re.I)
            if match:
                jobrole = match.group(1)
                break

        return {
            "name": name if name else "",
            "mailid": email.group() if email else "",
            "phone": phone.group() if phone else "",
            "jobrole": jobrole.title() if jobrole else "",
            "raw_text": text
        }

    @classmethod
    def extract_resume_details(cls, text: str) -> dict:
        """Deep extraction for Resume specific fields"""
        base_info = cls.extract_fields(text)
        
        # 1. Location
        loc_match = re.search(r"(?:from|in|at|located in)\s+([A-Z][a-z]+(?: [A-Z][a-z]+)*)", text)
        location = loc_match.group(1) if loc_match else "India"
        
        # 2. Education (Structured Extraction)
        education_list = []
        edu_matches = re.finditer(r"(B\.?Tech|Bachelor|Master|Degree|Diploma|SSC|HSC|Intermediate|Class\s*10|Class\s*12|Standard\s*10|Standard\s*12)\s+(?:in\s+)?([A-Za-z0-9 &]+?)\s+(?:from|at)\s+([A-Za-z0-9 \-\.,]+?)\s*((?:20\d\d)\s*-\s*(?:20\d\d|Present)?)", text, re.I)
        
        found_edu = False
        for m in edu_matches:
            found_edu = True
            education_list.append({
                "degree": f"{m.group(1)} {m.group(2)}",
                "university": m.group(3).strip(),
                "year": m.group(4).strip(),
                "grade": "" 
            })
            
        if not found_edu:
             lines = text.split('\n')
             for line in lines:
                 if "college" in line.lower() or "university" in line.lower() or "b.tech" in line.lower():
                     education_list.append({
                         "degree": line.strip(),
                         "university": "",
                         "year": "",
                         "grade": ""
                     })

        # 3. Projects
        projects_list = []
        project_segments = re.split(r"\bproject\b", text, flags=re.I)
        if len(project_segments) > 1:
            for seg in project_segments[1:]:
                 words = seg.split()[:20]
                 if words:
                    p_name = " ".join(words[:4]).title()
                    p_desc = " ".join(words[4:]).capitalize() + "."
                    projects_list.append({
                        "name": p_name,
                        "details": [p_desc]
                    })
            
        # 4. Skills
        skills_keywords = ["python", "java", "sql", "excel", "html", "css", "javascript", "react", "flutter", "aws", "c++", "c", "machine learning", "ai", "communication", "teamwork"]
        found_skills = [sk.title() for sk in skills_keywords if sk in text.lower()]
        skills_text = ", ".join(found_skills) if found_skills else "Python, SQL, Excel"
        
        base_info.update({
            "location": location if location else "",
            "summary": "",  
            "education": education_list if education_list else [],
            "projects": projects_list if projects_list else [],
            "roles": [],  
            "skills": skills_text if found_skills else "",
        })
        return base_info

    @staticmethod
    def parse_cover_letter_locally(text: str) -> dict:
        """
        Manually parses the structured resume text and builds the Gold Standard Narrative Cover Letter.
        This GUARANTEES the format even if AI fails.
        """
        name_match = re.search(r"(?:Name|Candidate Name):\s*(.*)", text, re.I)
        if name_match:
            name = name_match.group(1).strip()
        else:
            lines = [l.strip() for l in text.split('\n') if l.strip()]
            name = lines[0] if lines and len(lines[0]) < 50 else "Your Name"

        role_match = re.search(r"(?:Job Title|Role|Position):\s*(.*)", text, re.I)
        if role_match:
            role = role_match.group(1).strip()
        else:
            roles = ["Designer", "Developer", "Engineer", "Manager", "Analyst"]
            parsed_role = "Candidate"
            for line in text.split('\n')[:5]:
                for r in roles:
                    if r.lower() in line.lower():
                        parsed_role = line.strip()
                        break
            role = parsed_role

        email_match = re.search(r"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})", text)
        email = email_match.group(1).strip() if email_match else ""
        
        phone_match = re.search(r"(\+?\d[\d -]{8,15})", text)
        phone = phone_match.group(1).strip() if phone_match else ""
        
        companies = re.findall(r"(?:at|@)\s+([A-Za-z0-9 ]+?)\s+(?:\(|-|20)", text)
        if not companies:
             companies = re.findall(r"([A-Z][a-zA-Z0-9 ]+ (?:Solutions|Technologies|Systems|Corp|Inc|LLC|Pvt|Ltd))", text)
        
        company_1 = companies[0].strip() if len(companies) > 0 else "my previous company"
        company_2 = companies[1].strip() if len(companies) > 1 else None
        
        tools_match = re.search(r"(?:Tools|Skills):\s*(.*)", text, re.I)
        tools = tools_match.group(1).strip() if tools_match else "standard industry tools"
        
        p1 = (f"I am writing to apply for the {role} position at your organization. "
              f"With my robust background in this field, I am confident in my ability to contribute to your team.")
        
        p2 = (f"My name is {name}, and I am a {role}. "
              f"My background includes designing user-centered interfaces and creating high-quality solutions.")
        
        if company_2:
            p3 = (f"In my recent role at {company_1}, I worked on core product tools and improved user experiences. "
                  f"Prior to that, at {company_2}, I handled design and development tasks for various client projects.")
        else:
            p3 = (f"In my recent role at {company_1}, I worked on core product tools and improved user experiences, "
                  f"collaborating closely with cross-functional teams.")
                  
        p4 = (f"I am proficient in tools such as {tools}. "
              f"I enjoy creating clean, user-friendly solutions and improving overall process efficiency.")
              
        p5 = ("I am a quick learner, detail-oriented, and always willing to take on new challenges. "
              "I would be grateful for the opportunity to discuss how I can add value to your organization.")
              
        narrative_body = f"{p1}\n\n{p2}\n\n{p3}\n\n{p4}\n\n{p5}"
        
        return {
            "name": name,
            "email": email,
            "phone": phone,
            "jobrole": role,
            "body": narrative_body
        }

    @staticmethod
    def generate_content_with_gemini(text: str, doc_type: str = "resume") -> Optional[dict]:
        """Uses Google Gemini to extract and polish content."""
        if not settings.GEMINI_API_KEY:
            return None
        try:
            # Configure gemini locally inside method to avoid global pollution
            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel('gemini-flash-latest')
            
            if doc_type == "resume":
                prompt = (
                    "You are a STRICT Resume Data Extractor.\n"
                    "Your ONLY job is to extract data that is EXPLICITLY present in the user's input.\n\n"
                    "CRITICAL RULES – NEVER break these:\n"
                    "1. DO NOT invent, guess, or hallucinate ANY data.\n"
                    "2. If a field is NOT in the input, set it to empty string \"\" or empty list [].\n"
                    "3. Do NOT use placeholders like 'Your Name', 'University Name', 'Dates', 'N/A'.\n"
                    "4. Extract personal details (name, email, phone, location) EXACTLY as written.\n"
                    "5. For summary: only use text the user explicitly wrote. Do not generate one.\n\n"
                    "Return ONLY valid JSON (no markdown, no explanation):\n"
                    "{\n"
                    "  \"name\": \"\",\n"
                    "  \"email\": \"\",\n"
                    "  \"phone\": \"\",\n"
                    "  \"location\": \"\",\n"
                    "  \"summary\": \"\",\n"
                    "  \"education\": [],\n"
                    "  \"roles\": [],\n"
                    "  \"projects\": [],\n"
                    "  \"skills\": [],\n"
                    "  \"certifications\": []\n"
                    "}\n\n"
                    f"User Input: '{text}'"
                )
            else:
                prompt = (
                    "You are an expert professional resume writer. Write a COVER LETTER that strictly follows this EXACT structure and tone:\n"
                    "You MUST mention specific Company Names, Dates, and Projects found in the input.\n\n"
                    "REFERENCE STRUCTURE (Follow this exactly):\n"
                    "Paragraph 1: 'I am writing to express my interest in the [Role] position at your organization. With over [Years] of experience in [Field], along with strong hands-on expertise in [Key Skills], I am excited about the opportunity to contribute to your team.'\n\n"
                    "Paragraph 2: 'My name is [Name], and I am a [Role] based in [Location]. My background includes [Brief Summary of Core Competencies].'\n\n"
                    "Paragraph 3 (CRITICAL): 'In my recent role at [Company 1] ([Dates]), I [What you did]. Prior to that, at [Company 2] ([Dates]), I [What you did]. I also bring experience from [Company 3] where I [What you did].' (If only 1 company, expand on it).\n\n"
                    "Paragraph 4: 'I am proficient in tools such as [Tools List] and experienced in [Skills List]. Some of my project experience includes [Project List].'\n\n"
                    "Paragraph 5: 'Along with technical skills, I am [Soft Skills]. I am eager to bring my creativity and problem-solving ability to your organization.'\n\n"
                    "Paragraph 6: 'Thank you for considering my application...'\n\n"
                    "Do NOT include the header (Dear Hiring Manager) or footer (Sincerely) in the 'body' field. Just the paragraphs.\n"
                    "Return valid JSON with keys: name, email, phone, jobrole, body.\n"
                    f"Raw Input: '{text}'"
                )
                
            response = model.generate_content(prompt, generation_config={"response_mime_type": "application/json"})
            
            content = response.text.strip()
            if content.startswith("```json"):
                content = content[7:-3]
            
            print(f"Gemini Response: {repr(content)[:200]}...")
            return json.loads(content)
        except Exception as e:
            print(f"[ERROR] Gemini Error: {e}")
            return None

    @classmethod
    def generate_content_with_openai(cls, text: str, doc_type: str = "resume") -> Optional[dict]:
        """Uses OpenAI (or Mistral as first priority if key available) to extract/polish content."""
        if doc_type == "resume":
            prompt = (
                "You are a STRICT Resume Data Extractor. Your goal is to extract ONLY the information provided by the user.\n"
                "STRICT RULES:\n"
                "1. MANDATORY GENERATION (ALWAYS DO THIS): You MUST ALWAYS generate the 'professional_summary' (3-4 lines), 'experience_bullets' (4-5 highly detailed professional bullet points detailing their career achievements based on their skills), 'roles_and_responsibilities' (4-5 highly detailed professional bullet points describing daily tasks), and 'technical_skills' (a comprehensive list of skills appropriate for the role). Even if the user only provides their name and a job title, you MUST professionally generate these four sections.\n"
                "2. SUMMARY & EXPERIENCE: In the 'professional_summary', IF the user provides their years of experience, you MUST explicitly state it in the very first sentence.\n"
                "3. CONDITIONAL EXTRACTION (ONLY IF MENTIONED): 'education', 'projects', and 'years_of_experience' MUST ONLY be extracted if explicitly mentioned by the user. If they are missing, leave them empty ([] or \"\").\n"
                "4. NO HALLUCINATION: DO NOT invent personal data (Email, Phone, Education, Projects). NEVER generate fake Education or Projects.\n"
                "Return ONLY valid JSON in the following structure:\n"
                "{\n"
                "  \"name\": \"Full Name\",\n"
                "  \"email\": \"\",\n"
                "  \"phone\": \"\",\n"
                "  \"location\": \"\",\n"
                "  \"detected_role\": \"\",\n"
                "  \"years_of_experience\": \"\",\n"
                "  \"professional_summary\": \"\",\n"
                "  \"education\": [],\n"
                "  \"experience_bullets\": [],\n"
                "  \"roles_and_responsibilities\": [],\n"
                "  \"projects\": [],\n"
                "  \"technical_skills\": []\n"
                "}\n"
                "User Information:\n"
                f"<<< {text} >>>"
            )
        else:
            prompt = (
                "You are an expert professional resume writer. Write a COVER LETTER that strictly follows this EXACT structure and tone:\n"
                "You MUST mention specific Company Names, Dates, and Projects found in the input.\n\n"
                "REFERENCE STRUCTURE (Follow this exactly):\n"
                "Paragraph 1: 'I am writing to express my interest in the [Role] position at your organization. With over [Years] of experience in [Field], along with strong hands-on expertise in [Key Skills], I am excited about the opportunity to contribute to your team.'\n\n"
                "Paragraph 2: 'My name is [Name], and I am a [Role] based in [Location]. My background includes [Brief Summary of Core Competencies].'\n\n"
                "Paragraph 3 (CRITICAL): 'In my recent role at [Company 1] ([Dates]), I [What you did]. Prior to that, at [Company 2] ([Dates]), I [What you did]. I also bring experience from [Company 3] where I [What you did].' (If only 1 company, expand on it).\n\n"
                "Paragraph 4: 'I am proficient in tools such as [Tools List] and experienced in [Skills List]. Some of my project experience includes [Project List].'\n\n"
                "Paragraph 5: 'Along with technical skills, I am [Soft Skills]. I am eager to bring my creativity and problem-solving ability to your organization.'\n\n"
                "Paragraph 6: 'Thank you for considering my application...'\n\n"
                "Do NOT include the header (Dear Hiring Manager) or footer (Sincerely) in the 'body' field. Just the paragraphs.\n"
                "Return JSON with keys: name, email, phone, jobrole, body.\n"
                f"Raw Input: '{text}'"
            )

        # 1. Try Mistral AI (First Priority as requested)
        mistral_api_key = os.environ.get("MISTRAL_API_KEY", "ZVzUQWNuusFD28EPJZia3E6ecLrgC1Em")
        if mistral_api_key:
            try:
                from mistralai import Mistral
                client = Mistral(api_key=mistral_api_key)
                
                chat_response = client.chat.complete(
                    model="mistral-large-latest",
                    messages=[
                        {
                            "role": "system",
                            "content": "You are a helpful assistant that outputs only valid structured JSON."
                        },
                        {
                            "role": "user",
                            "content": prompt
                        },
                    ],
                    response_format={"type": "json_object"}
                )
                
                content = chat_response.choices[0].message.content
                print(f"Mistral Response: {repr(content)[:100]}...")
                return json.loads(content)
            except Exception as e:
                print(f"Mistral Error: {e}")
                
        # 2. Try OpenAI (Second Priority)
        if settings.OPENAI_API_KEY:
            try:
                # Set key on package to be sure
                openai.api_key = settings.OPENAI_API_KEY
                client = openai.OpenAI()
                response = client.chat.completions.create(
                    model="gpt-4o-mini", 
                    messages=[
                        {"role": "system", "content": "You are a helpful assistant that outputs only valid JSON."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.7,
                    response_format={"type": "json_object"}
                )
                
                content = response.choices[0].message.content
                print(f"OpenAI Response: {repr(content)[:100]}...")
                return json.loads(content)
            except Exception as e:
                print(f"OpenAI Error: {str(e)}")
                
        return None

    @classmethod
    def generate_content_ai(cls, text: str, doc_type: str = "resume") -> Optional[dict]:
        """Wrapper to choose between Gemini, OpenAI/Mistral."""
        # Force OpenAI for Resume if key is available (which falls back to Mistral first, then OpenAI)
        if doc_type == "resume" and settings.OPENAI_API_KEY:
            print("Using OpenAI/Mistral for Resume generation...")
            return cls.generate_content_with_openai(text, doc_type)
            
        if settings.GEMINI_API_KEY:
            print("Using Gemini...")
            return cls.generate_content_with_gemini(text, doc_type)
        elif settings.OPENAI_API_KEY:
            print("Using OpenAI/Mistral...")
            return cls.generate_content_with_openai(text, doc_type)
        else:
            return None

    @classmethod
    def generate_targeted_resume_content(cls, personal_info: str, job_description: str) -> str:
        """Generates tailored resume matching JD, using Mistral/OpenAI/Gemini."""
        prompt = (
            "You are an expert Resume Strategist. Your task is to craft a HIGH-IMPACT, TARGETED RESUME "
            "by aligning the user's personal info and experience with a specific Job Description (JD).\n\n"
            "STRICT RULES:\n"
            "1. ALIGNMENT: Highlight skills and experiences from the personal info that are most relevant to the JD.\n"
            "2. KEYWORDS: Incorporate relevant keywords from the JD naturally into the resume.\n"
            "3. STRUCTURE: Use the professional resume format with Name, Contact, Summary, Education, Experience, Projects, and Skills.\n"
            "4. QUALITY: Use powerful action verbs and quantified achievements where possible.\n\n"
            "User's Personal Info/Experience:\n"
            f"<<< {personal_info} >>>\n\n"
            "Target Job Description:\n"
            f"<<< {job_description} >>>\n\n"
            "Return the tailored resume as PLAIN TEXT in a professional layout. "
            "Start with the Name at the very top."
        )

        ai_data = None
        
        # 1. Try Mistral
        mistral_api_key = os.environ.get("MISTRAL_API_KEY", "ZVzUQWNuusFD28EPJZia3E6ecLrgC1Em")
        if mistral_api_key:
            try:
                from mistralai import Mistral
                client = Mistral(api_key=mistral_api_key)
                chat_response = client.chat.complete(
                    model="mistral-large-latest",
                    messages=[{"role": "user", "content": prompt}]
                )
                ai_data = chat_response.choices[0].message.content
            except Exception as e:
                print(f"Targeted Resume Mistral Error: {e}")

        # 2. Try OpenAI
        if not ai_data and settings.OPENAI_API_KEY:
            try:
                openai.api_key = settings.OPENAI_API_KEY
                client = openai.OpenAI()
                response = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[{"role": "user", "content": prompt}]
                )
                ai_data = response.choices[0].message.content
            except Exception as e:
                print(f"Targeted Resume OpenAI Error: {e}")

        # 3. Try Gemini
        if not ai_data and settings.GEMINI_API_KEY:
            try:
                genai.configure(api_key=settings.GEMINI_API_KEY)
                model = genai.GenerativeModel('gemini-flash-latest')
                response = model.generate_content(prompt)
                ai_data = response.text
            except Exception as e:
                print(f"Targeted Resume Gemini Error: {e}")

        if not ai_data:
            raise RuntimeError("AI generation failed. Please check your API keys.")

        return ai_data.strip()
