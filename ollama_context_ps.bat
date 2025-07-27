@echo off
REM Ollama Context PowerShell - Windows Batch Script
REM Usage: ollama_context_ps.bat "your question here"

if "%~1"=="" (
    echo Usage: ollama_context_ps.bat "your question here"
    echo Example: ollama_context_ps.bat "How does the authentication work?"
    pause
    exit /b 1
)

echo 🤖 Ollama Context PowerShell - Local AI Assistant
echo ================================================

powershell -ExecutionPolicy Bypass -File "powershell\ollama_context.ps1" -Question "%*"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Error running ollama_context.ps1
    echo Make sure PowerShell execution policy allows script execution
    pause
) 