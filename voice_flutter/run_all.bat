@echo off
setlocal
set PYTHONIOENCODING=utf-8

REM Define paths
set "BACKEND_DIR=%~dp0voice\whisper_backend"
set "APP_DIR=%~dp0voice\voice_app"
set "VENV_DIR=%BACKEND_DIR%\venv"
set "VENV_PYTHON=%VENV_DIR%\Scripts\python.exe"

echo [1/3] Checking Backend Environment...
pushd "%BACKEND_DIR%"

REM Check for Python
if exist "D:\Python314\python.exe" (
    set "PYTHON_EXE=D:\Python314\python.exe"
) else (
    set "PYTHON_EXE=python"
)

REM Create/Refresh venv if python missing
if not exist "%VENV_PYTHON%" (
    echo Creating virtual environment using %PYTHON_EXE%...
    "%PYTHON_EXE%" -m venv "%VENV_DIR%"
)

REM Install dependencies
"%VENV_PYTHON%" -m pip install -r requirements.txt
"%VENV_PYTHON%" -m pip install websockets

REM Start Backend
echo [2/3] Starting Backend Server...
start "VoiceBackend" "%VENV_PYTHON%" -m uvicorn main:app --reload --port 8001
popd

REM Wait for backend to potentially start
timeout /t 5 /nobreak >nul

REM Start Flutter App
echo [3/3] Launching Flutter App...
pushd "%APP_DIR%"

REM Kill any existing Chrome instances to avoid file-lock errors
echo Clearing Chrome processes...
taskkill /F /IM chrome.exe /T >nul 2>&1
timeout /t 2 /nobreak >nul

REM Clean stale Flutter Chrome temp profile to avoid Cookies file lock
if exist "D:\Temp\flutter_tools*" (
    echo Cleaning Flutter Chrome temp profiles...
    rmdir /s /q "D:\Temp" >nul 2>&1
)

flutter run -d chrome
popd

echo Done.
