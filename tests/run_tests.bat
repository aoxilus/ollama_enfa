@echo off
cd /d "%~dp0"
echo Running Ollama Desktop Cursor AI Tests...
echo ================================================
python python/test_ollama.py
pause