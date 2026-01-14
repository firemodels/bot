@echo off
setlocal EnableDelayedExpansion

set "INPUT_FILE=%~1"
set "PASS_THROUGH=0"

if not exist "%INPUT_FILE%" (
    echo Input file not found
    exit /b 1
)

for /f "usebackq delims=" %%L in ("%INPUT_FILE%") do (

    REM Once SCAN SUMMARY is seen, just echo lines as-is
    if !PASS_THROUGH! EQU 1 (
        echo %%L
    ) else (
        echo %%L | findstr /C:"SCAN SUMMARY" >nul
        if not errorlevel 1 (
            set "PASS_THROUGH=1"
            echo %%L
        ) else (
            REM Parse: filename + rest of line
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
    )
)
endlocal
