from pydantic import BaseModel

class GenerateRequest(BaseModel):
    text: str
    name: str = ""
    email: str = ""
    phone: str = ""
    jobrole: str = ""
    template_id: str = "classic" 

class TargetedResumeRequest(BaseModel):
    personal_info: str
    job_description: str
    template_id: str = "classic"

class VoiceText(BaseModel):
    text: str
