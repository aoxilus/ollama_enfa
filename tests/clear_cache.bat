@echo off
cd /d "%~dp0"
echo Clearing Ollama cache...
python -c "from python.ollama_cache import clear_cache; print(f'Cleared {clear_cache()} cache entries')"
pause