<#
# Quick Start Script for Whisper Backend
# Run this script to start the backend server
#>

$ScriptPath = Join-Path $PSScriptRoot "..\backend"
Set-Location $ScriptPath
$VenvPath = Join-Path $ScriptPath "venv"

# Check if virtual environment exists, if not, create it and install dependencies
if (-not (Test-Path $VenvPath)) {
    Write-Host "🔧 Virtual environment not found. Creating one now..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "📦 Installing dependencies from requirements.txt..." -ForegroundColor Cyan
    # Activate and install in the same powershell process
    & "$VenvPath\Scripts\pip.exe" install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error installing dependencies. Please check requirements.txt and your pip installation." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Dependencies installed successfully." -ForegroundColor Green
}

Write-Host "🚀 Starting Whisper Backend..." -ForegroundColor Green

# Activate virtual environment
Write-Host "📦 Activating virtual environment..." -ForegroundColor Cyan
& "$VenvPath\Scripts\Activate.ps1"

# Start the server
Write-Host "🌐 Starting FastAPI server on http://localhost:8001" -ForegroundColor Green
Write-Host "📚 API Documentation: http://127.0.0.1:8001/docs" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Explicitly use the python from the venv to run uvicorn
& "$VenvPath\Scripts\python.exe" -m uvicorn app.main:app --reload --port 8001
