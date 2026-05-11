# Fix for C: Drive Full (Error 112)
# We redirect the temporary files to the D: drive (local build folder)
$localTemp = "$PSScriptRoot\build\custom_temp"
if (!(Test-Path $localTemp)) { New-Item -ItemType Directory -Force -Path $localTemp | Out-Null }

# Set environment variables for this session ONLY
$env:TEMP = $localTemp
$env:TMP = $localTemp

Write-Host "Using local temp directory to avoid C: drive space issues: $localTemp"

# Force kill any stuck Chrome processes
Write-Host "Cleaning up stuck Chrome processes..."
Stop-Process -Name chrome -ErrorAction SilentlyContinue -Force

# Kill any stuck Flutter instances
Write-Host "Cleaning up stuck Flutter instances..."
Stop-Process -Name flutter -ErrorAction SilentlyContinue -Force
Stop-Process -Name dart -ErrorAction SilentlyContinue -Force

Write-Host "Starting Flutter App..."
flutter run -d chrome
