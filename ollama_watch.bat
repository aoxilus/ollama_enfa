@echo off
REM Ollama Watch - Monitoreo automático de archivos con IA
REM Uso: ollama_watch.bat [pregunta] o ollama_watch.bat (modo automático)

if "%1"=="" (
    echo Iniciando modo automático (vigilancia de archivos)...
    powershell -ExecutionPolicy Bypass -File "powershell\ollama_watch.ps1"
) else (
    echo Modo manual: "%*"
    powershell -ExecutionPolicy Bypass -File "powershell\ollama_watch.ps1" -Manual -Question "%*"
) 