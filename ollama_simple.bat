@echo off
REM Ollama Simple - Windows Batch Script
REM Usage: ollama_simple.bat "your question here"

if "%~1"=="" (
    echo Usage: ollama_simple.bat "your question here"
    echo Example: ollama_simple.bat "¿Qué archivos hay en este proyecto?"
    pause
    exit /b 1
)

echo 🤖 Ollama Simple - Local AI Assistant
echo =====================================

python python\ollama_simple.py %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Error running ollama_simple.py
    echo Make sure Python and requests module are installed:
    echo pip install -r python\requirements.txt
    pause
) 