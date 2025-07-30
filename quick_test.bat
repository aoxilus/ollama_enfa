@echo off
REM Quick test with timeout protection
REM Usage: quick_test.bat [model] [question] [timeout]

setlocal enabledelayedexpansion

set MODEL=%1
if "%MODEL%"=="" set MODEL=codellama:7b-code-q4_K_M

set QUESTION=%2
if "%QUESTION%"=="" set QUESTION="What is 2+2?"

set TIMEOUT=%3
if "%TIMEOUT%"=="" set TIMEOUT=30

echo 🚀 Quick test with timeout protection
echo 📝 Model: %MODEL%
echo ❓ Question: %QUESTION%
echo ⏱️  Timeout: %TIMEOUT% seconds
echo.

REM Test with timeout using PowerShell
powershell -Command "& { $job = Start-Job -ScriptBlock { param($m, $q, $t) python test_fast.py $m $q } -ArgumentList '%MODEL%', '%QUESTION%', %TIMEOUT%; if (Wait-Job -Job $job -Timeout %TIMEOUT%) { Receive-Job -Job $job; Remove-Job -Job $job } else { Remove-Job -Job $job -Force; Write-Host '⏰ Timeout reached after %TIMEOUT% seconds' -ForegroundColor Red } }"

echo.
echo 🏁 Test completed 