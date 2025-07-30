@echo off
REM Quick test with timeout protection
REM Usage: quick_test.bat [model] [question] [timeout]

if "%1"=="" (
    echo Usage: quick_test.bat [model] [question] [timeout]
    echo Example: quick_test.bat codellama:7b-code-q4_K_M "What is 2+2?" 30
    exit /b 1
)

set MODEL=%1
set QUESTION=%2
set TIMEOUT=%3

if "%TIMEOUT%"=="" set TIMEOUT=30

echo Quick test with timeout protection
echo Model: %MODEL%
echo Question: %QUESTION%
echo Timeout: %TIMEOUT% seconds
echo.

python tests/test_fast.py %MODEL% %QUESTION%

echo.
echo Test completed 