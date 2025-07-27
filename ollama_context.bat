@echo off
REM Ollama Context - Windows Batch Script
REM Usage: ollama_context.bat "your question here"

if "%~1"=="" (
    echo Usage: ollama_context.bat "your question here"
    echo Example: ollama_context.bat "How does the authentication work?"
    pause
    exit /b 1
)

echo 🤖 Ollama Context - Local AI Assistant
echo ======================================

python python\ollama_context.py %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Error running ollama_context.py
    echo Make sure Python and requests module are installed:
    echo pip install -r python\requirements.txt
    pause
) 