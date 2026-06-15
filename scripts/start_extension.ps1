# Voice to Text Extension - Quick Start Guide

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Voice to Text Chrome Extension Setup  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if backend dependencies are installed
Write-Host "[1/3] Checking backend dependencies..." -ForegroundColor Yellow
$backendPath = Join-Path $PSScriptRoot "..\backend"

try {
    python -c "import fastapi" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Backend dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "✗ Installing backend dependencies..." -ForegroundColor Red
        Set-Location $backendPath
        pip install -r requirements.txt
    }
} catch {
    Write-Host "✗ Python not found or dependencies missing" -ForegroundColor Red
    Write-Host "  Please install Python and run: pip install -r requirements.txt" -ForegroundColor Yellow
    exit 1
}

# Step 2: Start the backend server
Write-Host ""
Write-Host "[2/3] Starting FastAPI backend server..." -ForegroundColor Yellow
Set-Location $backendPath

Write-Host "Backend will start on: http://127.0.0.1:8001" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  NEXT STEPS - LOAD CHROME EXTENSION    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open Chrome and go to: chrome://extensions/" -ForegroundColor White
Write-Host "2. Enable 'Developer mode' (toggle in top-right)" -ForegroundColor White
Write-Host "3. Click 'Load unpacked'" -ForegroundColor White
Write-Host "4. Select folder: <project-root>\frontend\chrome_extension" -ForegroundColor White
Write-Host "5. Click the extension icon to start using it!" -ForegroundColor White
Write-Host ""
Write-Host "Features:" -ForegroundColor Green
Write-Host "  • Extended listening time with auto-restart" -ForegroundColor White
Write-Host "  • 300-500 word limit with visual feedback" -ForegroundColor White
Write-Host "  • Real-time word count display" -ForegroundColor White
Write-Host "  • Multi-language support (11+ languages)" -ForegroundColor White
Write-Host "  • Editable transcription output" -ForegroundColor White
Write-Host "  • Save to Excel/Google Sheets" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the server
python -m uvicorn app.main:app --reload --port 8001
