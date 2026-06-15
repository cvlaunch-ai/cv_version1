# Security Hardening Implementation Plan

This document outlines the security architecture roadmap for hardening the Voice Flutter FastAPI backend against standard API vulnerabilities.

---

## 1. Authentication & JWT Layer

Currently, the backend has open endpoints with no access control. We will introduce JWT-based OAuth2 authentication.

### Flow & Architecture
- **Bearer Tokens**: Implement OAuth2 password bearer flow using standard JWT (JSON Web Tokens).
- **Access Tokens**: Short-lived tokens (e.g., 15-minute expiry).
- **Refresh Tokens**: Long-lived secure HttpOnly cookies (e.g., 7-day expiry) stored in a backend cache (Redis/Database) to refresh access tokens.
- **Crypto Engine**: Use `passlib[bcrypt]` for password hashing and `python-jose` for encoding and decoding tokens.

---

## 2. Authorization (Role-Based Access Control)

Restrict access to routes based on user credentials and roles.

### Policies & Enforcement
- **Roles**:
  - `User`: Can transcribe audio, generate resumes, download documents, and manage their own profiles.
  - `Admin`: Can view all lead tables, access Sheets logging reports, and configure model settings.
- **Dependencies**: Use FastAPI's dependency injection system (`Depends`) to inject active user scopes into routers, verifying permissions before executing endpoints.

---

## 3. API Rate Limiting

Prevent Denial of Service (DoS) and API abuse, especially on expensive OpenAI/Gemini wrapper routes.

### Limits & Backend
- **Middleware**: Integrate `slowapi` (FastAPI wrapper around `limits`).
- **Storage**: Use Redis for distributed rate-limiting or an in-memory memory limit storage for single-instance development.
- **Thresholds**:
  - `/transcribe` and `/chat-resume` (Expensive endpoints): 5 requests per minute per user/IP.
  - `/pdf/*` conversion routes: 10 requests per minute per user/IP.
  - General routes: 60 requests per minute per user/IP.

---

## 4. Input Validation & Request Validation

Protect against injection, SQL injection, and buffer overflows.

### Validation Strategies
- **Pydantic Validation**: Ensure all requests use typed Pydantic request body models rather than generic dictionaries (`dict = Body(...)`).
- **Regex Restrictions**: Validate personal data fields (Email, Phone) using strict regex patterns on schema definitions.
- **Sanitization**: Strip HTML/Markdown tags from input text (e.g., using `bleach`) before passing variables to AI prompt templates or formatting engines to prevent prompt injection and XSS payloads.

---

## 5. File Upload Validation

Secure endpoints like `/transcribe` and `/pdf/*` which accept file uploads.

### Restricting Payloads
- **MIME Type Checks**: Verify file headers (magic bytes) to ensure uploaded files match expected types (e.g., `audio/webm`, `application/pdf`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`). Do not rely on file extension alone.
- **File Size Limits**: Enforce maximum file upload sizes in middleware:
  - Audio files: Max 10MB.
  - Documents (PDF, Excel, Word): Max 15MB.
- **Filename Sanitization**: Strip directory traversal patterns (`../`) from names using `werkzeug.utils.secure_filename` to prevent writing files to arbitrary paths.

---

## 6. Secret Management

Remove inline credentials and configure settings securely.

### Implementation Checklist
- **System Env Vars**: Read all secrets (AI keys, sheets oauth credentials, JWT secrets) from OS environment variables.
- **Credentials File Protection**: Google Sheets `credentials.json` must be encrypted or loaded dynamically as a JSON string from environment variables instead of being stored as a raw file in the repository workspace.
- **Git Safety**: Add `.env`, `credentials.json`, and any certificate files explicitly to the `.gitignore`.

---

## 7. CORS Hardening

Limit which origin origins can consume the API.

### Policy Re-configuration
- **Restrict Wildcard**: Replace `allow_origins=["*"]` with an environment-specified white-list (e.g., `allow_origins=["https://your-production-app.com"]` in production).
- **Credentials Policy**: Only set `allow_credentials=True` when origins are restricted, enabling secure session cookies or refresh tokens.

---

## 8. Audit Logging & Security Events

Provide visibility into system utilization and security breaches.

### Logging Design
- **Sensitive Operations**: Log all document deletions, API generation requests, authentication failures, and rate-limiting triggers.
- **Log Masking**: Ensure personal identification details (names, emails, phone numbers) are masked in server stdout/logs.
- **Log Aggregator**: Send log outputs to a central location (e.g., CloudWatch, GCP Logging, or local rotative files in `logs/` directory) and set up notifications for multiple high-frequency failure alerts.
