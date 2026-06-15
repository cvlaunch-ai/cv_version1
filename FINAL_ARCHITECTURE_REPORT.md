# Final Architecture Report

This report validates the final clean architecture implementation of the Voice Flutter backend.

---

## 1. Architectural Status Checklist

- **[x] No business logic in `main.py`**: `main.py` is now a slim 30-line entrypoint that handles only FastAPI initialization, CORS middleware configuration, routes registration, and startup lifespan events.
- **[x] API endpoints inside `routers/`**: All routes are segmented into separate endpoint routers.
- **[x] Business logic inside `services/`**: Handlers for speech transcription, translation, and AI generation are encapsulated inside services.
- **[x] File/Database operations inside `repositories/`**: Google Sheets, local Excel, and local CSV write operations are fully extracted to `LeadRepository`.
- **[x] Configuration loaded from `core/config.py`**: Absolute settings and PATH variables are loaded globally.
- **[x] Pytest runs successfully**: 5 functional REST tests executed and passed successfully.
- **[x] Uvicorn starts successfully**: Live server launched on port 8001.

---

## 2. Folder Tree

```
backend/app/
├── core/                     # Configuration and core infrastructure
│   ├── __init__.py
│   ├── config.py             # Settings, env vars, absolute path calculations
│   ├── exceptions.py         # Custom application exceptions
│   └── logging.py            # Standard log config
├── prompts/                  # AI Prompts package
│   ├── __init__.py           # Prompt constants
├── schemas/                  # Request validation schemas
│   ├── __init__.py
│   └── requests.py           # Pydantic models
├── repositories/             # Persistence and IO layers
│   ├── __init__.py
│   └── lead_repository.py    # LeadRepository (CSV, Sheets, Excel logging)
├── services/                 # Core business services
│   ├── __init__.py
│   ├── pdf_service.py        # PDF templates and conversions
│   ├── resume_service.py     # Resume parsers and AI builders
│   ├── translation_service.py# Translator utilities
│   └── whisper_service.py    # Local speech transcribers
├── routers/                  # API routers
│   ├── __init__.py
│   ├── cover_letter.py       # Cover letter endpoints
│   ├── lead.py               # Parse and save endpoint
│   ├── pdf.py                # PDF toolkit endpoints
│   ├── resume.py             # Resume endpoints
│   ├── root.py               # Root endpoint
│   └── transcribe.py         # Audio transcribe REST/WebSocket
└── main.py                   # App startup orchestrator
```

---

## 3. Inventory

### API Endpoint Inventory
| Method | Route | Router Module | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | [root.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/root.py) | Service health check |
| `POST` | `/transcribe` | [transcribe.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/transcribe.py) | Transcribe audio payload |
| `WEBSOCKET` | `/ws/transcribe` | [transcribe.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/transcribe.py) | Real-time WebSocket audio transcription |
| `POST` | `/parse-and-save` | [lead.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/lead.py) | Text parse and Excel append |
| `POST` | `/generate-cover-letter-pdf` | [cover_letter.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/cover_letter.py) | PDF Cover Letter generation |
| `POST` | `/download-cover-letter` | [cover_letter.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/cover_letter.py) | TXT Cover Letter streaming |
| `POST` | `/generate-cover-letter-json` | [cover_letter.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/cover_letter.py) | JSON Cover Letter generation |
| `POST` | `/generate-resume-pdf` | [resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) | PDF Resume generation |
| `POST` | `/download-resume` | [resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) | TXT Resume streaming |
| `POST` | `/chat-resume` | [resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) | Conversational helper prompts |
| `POST` | `/generate-resume-json` | [resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) | JSON Resume extraction |
| `POST` | `/generate-targeted-resume` | [resume.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/resume.py) | Tailor Resume to Job Description |
| `POST` | `/pdf/merge` | [pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) | Merges multiple PDFs |
| `POST` | `/pdf/split` | [pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) | Splits PDF into ZIP of pages |
| `POST` | `/pdf/to-word` | [pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) | PDF to Word document conversion |
| `POST` | `/pdf/word-to-pdf` | [pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) | Word document to PDF conversion |
| `POST` | `/pdf/compress` | [pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) | Compresses PDF streams |
| `POST` | `/pdf/to-excel` | [pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) | PDF to Excel spreadsheet conversion |
| `POST` | `/pdf/excel-to-pdf` | [pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) | Excel spreadsheet to PDF conversion |
| `POST` | `/pdf/ppt-to-pdf` | [pdf.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/routers/pdf.py) | PowerPoint to PDF conversion |

### Service Inventory
| Service Name | Class Name | File Path | Main Operations |
| :--- | :--- | :--- | :--- |
| Translation Service | `TranslationService` | [translation_service.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/services/translation_service.py) | `translate_to_english` |
| Whisper Service | `WhisperService` | [whisper_service.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/services/whisper_service.py) | `transcribe_file`, `transcribe_bytes`, lazy load model cache |
| Resume Service | `ResumeService` | [resume_service.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/services/resume_service.py) | Parsing logic, AI prompt formatting and generation (Gemini, OpenAI, Mistral) |
| PDF Service | `PDFService` | [pdf_service.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/services/pdf_service.py) | PDF templates generation (ReportLab), Docx parsing, and headless LibreOffice command runners |

### Repository Inventory
| Repository Name | Class Name | File Path | Main Operations |
| :--- | :--- | :--- | :--- |
| Lead Repository | `LeadRepository` | [lead_repository.py](file:///c:/Users/Prath/OneDrive/Desktop/voice_flutter12233/voice_flutter12233/backend/app/repositories/lead_repository.py) | `save_lead_data` (Google Sheets & local CSV), `save_lead_excel` (local openpyxl Excel spreadsheet logging) |

---

## 4. Technical Debt Log

The refactoring has significantly reduced technical debt, but the following areas represent opportunities for future improvement:

1. **Lazy Imports inside Methods**:
   - Several services import heavy dependencies locally (e.g. `import pandas as pd` and `from pdf2docx import Converter`) to avoid overhead at boot. As the codebase grows, these should be handled via dynamic dependencies or run in a background task queue (e.g., Celery/Redis).
2. **Synchronous I/O in Handlers**:
   - Excel and CSV file logging (`openpyxl`, `csv`) are synchronous blocking operations. Under high concurrent request volumes, these will block the single-threaded asyncio event loop.
3. **Robust AI Prompt Error Recovery**:
   - The AI generation functions fallback to regex/local parser blocks if API exceptions are raised. Moving forward, these fallbacks should include standard exponential backoff retries.
4. **Hardcoded Sheets URL**:
   - Google Sheet URL `https://docs.google.com/spreadsheets/d/1...` is currently hardcoded in the repository layer. It should be moved to settings variables in `.env` and loaded via `Settings`.
