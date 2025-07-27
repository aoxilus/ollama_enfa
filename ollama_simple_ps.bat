@echo off
REM Ollama Simple PowerShell - Windows Batch Script
REM Usage: ollama_simple_ps.bat "your question here"

if "%~1"=="" (
    echo Usage: ollama_simple_ps.bat "your question here"
    echo Example: ollama_simple_ps.bat "¿Qué archivos hay en este proyecto?"
    pause
    exit /b 1
)

echo 🤖 Ollama Simple PowerShell - Local AI Assistant
echo ================================================

powershell -ExecutionPolicy Bypass -File "powershell\ollama_simple.ps1" -Question "%*"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Error running ollama_simple.ps1
    echo Make sure PowerShell execution policy allows script execution
    pause
) 