@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "powershell\ollama_simple_async_pure.ps1" %*