@echo off
echo === Quick Ollama Test ===
echo.

if "%1"=="" (
    echo Usage: quick_test.bat "question"
    echo Example: quick_test.bat "What is 2+2?"
    pause
    exit /b 1
)

echo Testing: %1
echo.

ollama run codellama:7b-code-q4_K_M "%1"

echo.
echo Test completed.
pause 