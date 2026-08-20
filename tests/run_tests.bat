@echo off
cd /d "%~dp0"
echo Running Aoxilus Butler Tests...
echo ================================================
python python/test_ollama.py
pause