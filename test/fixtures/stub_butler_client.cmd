@echo off
REM Unit-test stub: mimics ollama_client machine output (no HTTP).
if /i "%~1"=="ask" (
  echo STUB_OK
  exit /b 0
)
if /i "%~1"=="fast" (
  echo STUB_FAST
  exit /b 0
)
echo STUB_BAD_VERB 1>&2
exit /b 2
