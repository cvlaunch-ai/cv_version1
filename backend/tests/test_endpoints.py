import sys
import os
import pytest
from fastapi.testclient import TestClient

# Add app directory to path so imports work correctly during test
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "[MIC] Free Whisper API - Running locally!", "status": "ready"}

def test_parse_and_save_mock():
    # Send request with basic details
    payload = {
        "text": "My name is John Doe, email is john.doe@example.com, phone is 9876543210. I am applying for Python Developer role."
    }
    response = client.post("/parse-and-save", json=payload)
    assert response.status_code == 200
    res_data = response.json()
    assert "status" in res_data
    assert "data" in res_data
    assert res_data["data"]["name"] == "John Doe"
    assert res_data["data"]["mailid"] == "john.doe@example.com"
    assert res_data["data"]["phone"] == "9876543210"
    assert res_data["data"]["jobrole"] == "Developer"

def test_generate_cover_letter_json():
    payload = {
        "text": "Candidate Name: Jane Smith, Role: Software Engineer, email: jane@example.com, phone: 9999999999, at Tech Solutions."
    }
    response = client.post("/generate-cover-letter-json", json=payload)
    assert response.status_code == 200
    res_data = response.json()
    assert "cover_letter" in res_data
    assert "Jane Smith" in res_data["cover_letter"]
    assert "Software Engineer" in res_data["cover_letter"]

def test_chat_resume():
    payload = {
        "message": "Hello, I want to add Python to my skills",
        "history": [{"role": "user", "text": "Hi"}, {"role": "assistant", "text": "Hello, let's build your resume."}]
    }
    response = client.post("/chat-resume", json=payload)
    assert response.status_code == 200
    res_data = response.json()
    assert "message" in res_data
    assert "ready" in res_data

def test_generate_resume_json_literal():
    # Tests formatted resume literal parsing path (needs > 15 lines and pipes)
    text = (
        "John Doe\n"
        "| 9876543210 | john@example.com | Hyderabad, India |\n"
        "Professional Summary\n"
        "Highly motivated and skilled software developer with strong foundation.\n"
        "Experienced in building scalable backend web applications.\n"
        "Education\n"
        "Bachelor of Technology in Computer Science\n"
        "Jawaharlal Nehru Technological University, 2020-2024\n"
        "Roles & Responsibilities\n"
        "Developed Python FastAPI applications and REST APIs.\n"
        "Designed database models and integrated Google Sheets API.\n"
        "Projects\n"
        "Voice Assistant Project: A smart transcription and parsing system.\n"
        "PDF Toolkit Project: A utility for split, merge, and compress operations.\n"
        "Technologies & Tools\n"
        "Python, FastAPI, Flutter, OpenPyXL, Pandas"
    )
    payload = {"text": text}
    response = client.post("/generate-resume-json", json=payload)
    assert response.status_code == 200
    res_data = response.json()
    assert "resume" in res_data
    assert "John Doe" in res_data["resume"]
    assert "Professional Summary" in res_data["resume"]
    assert "FastAPI" in res_data["resume"]

