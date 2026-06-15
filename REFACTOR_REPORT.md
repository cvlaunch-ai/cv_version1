# Refactor Report

This report documents the architectural reorganization of the Voice Flutter backend from a monolithic structure (`backend/app/main.py`) to a Clean Enterprise Architecture under `backend/app/`.

---

## 1. Architectural Directory Layout

The new project structure separates configurations, database/sheets integrations, business logic, endpoints, and data validation models into clear layout layers:

```
backend/app/
├── core/
│   ├── __init__.py
│   ├── config.py             # Environment settings and paths
│   ├── exceptions.py         # App-level exceptions
│   └── logging.py            # Logger definitions
├── prompts/
│   ├── __init__.py           # Unified location for AI prompts
├── schemas/
│   ├── __init__.py
│   └── requests.py           # Pydantic request models
├── repositories/
│   ├── __init__.py
│   └── lead_repository.py    # Sheet and local CSV writers
├── services/
│   ├── __init__.py
│   ├── translation_service.py# Deep translation helpers
│   ├── whisper_service.py    # Local speech-to-text engines
│   ├── resume_service.py     # AI parsers and text generators
│   └── pdf_service.py        # PDF generators and format converters
├── routers/
│   ├── __init__.py
│   ├── root.py               # Root status checker
│   ├── transcribe.py         # Audio transcribe endpoints (REST + WebSocket)
│   ├── lead.py               # Sheet parsing logger
│   ├── cover_letter.py       # Cover letter generators
│   ├── resume.py             # Resume generators
│   └── pdf.py                # PDF and Docx toolkit
└── main.py                   # Slim FastAPI application entrypoint
```

---

## 2. Code Relocation Mappings

All endpoints and helper methods from the original monolithic `main.py` were moved to their respective Clean Architecture modules:

### Core Configurations & Models
| Original Component (in monolithic `main.py`) | Target File Path | Description |
| :--- | :--- | :--- |
| `load_dotenv`, `os.environ["PATH"]` adjustments, LibreOffice path lists, directories setup | [backend/app/core/config.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/core/config.py) | Centralizes variable loads and filesystem path bindings |
| Standard `print` logging setup | [backend/app/core/logging.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/core/logging.py) | Implements standardized Python logging |
| Inline exceptions | [backend/app/core/exceptions.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/core/exceptions.py) | Structured app exception classes |
| `class GenerateRequest`, `class TargetedResumeRequest`, `class VoiceText` | [backend/app/schemas/requests.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/schemas/requests.py) | Pydantic Request Models |
| `RESUME_EXTRACT_PROMPT`, `COVER_LETTER_PROMPT` | [backend/app/prompts/__init__.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/prompts/__init__.py) | AI prompt templates (replaced deleted `prompts.py`) |

### Repositories & Services
| Original Component (in monolithic `main.py`) | Target File Path | Description |
| :--- | :--- | :--- |
| `def save_data` | [backend/app/repositories/lead_repository.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/repositories/lead_repository.py) | Google Sheets append and CSV file fallbacks |
| `def translate_to_english` | [backend/app/services/translation_service.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/services/translation_service.py) | Translation from deep-translator |
| `whisper.load_model("base")` | [backend/app/services/whisper_service.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/services/whisper_service.py) | Lazy loads, caches, and transcribes audio |
| `generate_content_with_gemini`, `generate_content_with_openai`, `generate_content_ai`, `extract_fields`, `extract_resume_details`, `parse_formatted_resume`, `parse_structured_resume`, `build_resume_string`, `build_resume_data`, `parse_cover_letter_locally` | [backend/app/services/resume_service.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/services/resume_service.py) | AI content generators and structured string compilers |
| `get_soffice_path`, `convert_with_libreoffice`, `_create_text_file`, `_create_platypus_pdf`, `_get_styles`, `_create_classic_pdf_internal`, `_create_modern_resume`, `_convert_docx_to_pdf_internal` | [backend/app/services/pdf_service.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/services/pdf_service.py) | ReportLab templates, Docx structure parsing, and soffice runners |

### API Routers
| Monolithic Endpoint | Clean Router Path | Target File Path |
| :--- | :--- | :--- |
| `GET /` | Root router | [backend/app/routers/root.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/root.py) |
| `POST /transcribe` | Transcribe router | [backend/app/routers/transcribe.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/transcribe.py) |
| `WEBSOCKET /ws/transcribe` | Transcribe router | [backend/app/routers/transcribe.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/transcribe.py) |
| `POST /parse-and-save` | Lead router | [backend/app/routers/lead.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/lead.py) |
| `POST /generate-cover-letter-pdf` | Cover Letter router | [backend/app/routers/cover_letter.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/cover_letter.py) |
| `POST /download-cover-letter` | Cover Letter router | [backend/app/routers/cover_letter.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/cover_letter.py) |
| `POST /generate-cover-letter-json` | Cover Letter router | [backend/app/routers/cover_letter.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/cover_letter.py) |
| `POST /generate-resume-pdf` | Resume router | [backend/app/routers/resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) |
| `POST /download-resume` | Resume router | [backend/app/routers/resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) |
| `POST /chat-resume` | Resume router | [backend/app/routers/resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) |
| `POST /generate-resume-json` | Resume router | [backend/app/routers/resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) |
| `POST /generate-targeted-resume` | Resume router | [backend/app/routers/resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) |
| `POST /pdf/merge` | PDF router | [backend/app/routers/pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) |
| `POST /pdf/split` | PDF router | [backend/app/routers/pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) |
| `POST /pdf/to-word` | PDF router | [backend/app/routers/pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) |
| `POST /pdf/word-to-pdf` | PDF router | [backend/app/routers/pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) |
| `POST /pdf/compress` | PDF router | [backend/app/routers/pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) |
| `POST /pdf/to-excel` | PDF router | [backend/app/routers/pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) |
| `POST /pdf/excel-to-pdf` | PDF router | [backend/app/routers/pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) |
| `POST /pdf/ppt-to-pdf` | PDF router | [backend/app/routers/pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) |

---

## 3. Key Benefits

1. **Uncoupled Routes & Core Logic**: Allows separate maintenance of routing definitions from service modules.
2. **Standardized Settings Management**: Central settings object makes environment scaling simple.
3. **Optimized Whisper Loading**: Pre-loads the Whisper model on startup in the lifespan config rather than blocking on the first inbound request.
4. **Improved Coverage & Testing**: Tests can now target specific service modules or mock client endpoint calls directly.
