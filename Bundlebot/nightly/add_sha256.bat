@echo off
setlocal EnableDelayedExpansion

set "INPUT_FILE=%~1"
set "PASS_THROUGH=0"

if not exist "%INPUT_FILE%" (
    echo Input file not found
    exit /b 1
)

for /f "usebackq delims=" %%L in ("%INPUT_FILE%") do (
  for /f "tokens=1,* delims= " %%A in ("%%L") do (
    set "HASH="
    set "FILENAME=%%A"
    if "!FILENAME:~-1!"==":" set "FILENAME=!FILENAME:~0,-1!"
    if exist !FILENAME! (
      certutil -hashfile !FILENAME! SHA256 | head -2 | tail -1 > hash.out
      set /p HASH=<hash.out
    )
    set "FILENAME=!FILENAME:%userprofile%\.bundle\uploads\=!"
    echo !FILENAME!,!HASH!,%%B
  )
)
endlocal
