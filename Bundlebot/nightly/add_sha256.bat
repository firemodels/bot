@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Base directory (equivalent to $HOME/.bundle/bundles)
set "BASE=%USERPROFILE%\.bundle\bundles"

:: Input file (default: stdin via redirected input)
if "%~1"=="" (
    set "INPUT=CON"
) else (
    set "INPUT=%~1"
)

for /f "usebackq delims=" %%L in ("%INPUT%") do (
    set "LINE=%%L"

    :: Skip empty lines
    if not defined LINE (
        echo.
        goto :continue
    )

    :: Extract file path (up to first space)
    for /f "tokens=1*" %%A in ("!LINE!") do (
        set "FILEPATH=%%A"
        set "TEXT=%%B"
    )

    :: Remove trailing colon from filepath (if present)
    if "!FILEPATH:~-1!"==":" set "FILEPATH=!FILEPATH:~0,-1!"

    set "FULLFILE=%BASE%\!FILEPATH!"

    :: If file does not exist, echo original line
    if not exist "!FULLFILE!" (
        echo !LINE!
        goto :continue
    )

    :: Compute SHA256 using certutil
    for /f "skip=1 tokens=1" %%H in ('
        certutil -hashfile "!FULLFILE!" SHA256 ^| findstr /v "hash"
    ') do (
        set "SHA256=%%H"
        goto :hashdone
    )
    :hashdone

    :: Output: filename,sha256,text
    echo !FILEPATH!,!SHA256!,!TEXT!

    :continue
)

endlocal
