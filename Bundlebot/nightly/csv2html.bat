@echo off
setlocal EnableExtensions

set CDIR=%CD%
set bindir=..\..\scripts\bin
cd %bindir%
set bindir=%CD%
cd %CDIR%
set gawk=%bindir%\gawk.exe

:: ---- Input handling ----
if "%~1"=="" (
    echo Usage: %~nx0 inputfile
    exit /b 1
)

set "INPUT=%~1"
set "INPUTTEMP=%INPUT%.%RANDOM%"
set "TITLE=%~n1"
set "OUTPUT=%~n1_manifest.html"

:: ---- sed replacement (same as Bash) ----
sed "s/: OK/OK/g" "%INPUT%" > "%INPUTTEMP%"

:: ---- HTML header ----
(
echo ^<html^>^<head^>^<title^>%TITLE% Manifest^</title^>^</head^>
echo ^<body^>
echo ^<h1^>%TITLE% Manifest^</h1^>
echo ^<table border=on^>
echo ^<tr^>^<th^>file^</th^>^<th^>sha256 hash^</th^>^<th^>virus status^</th^>^</tr^>
) > "%OUTPUT%"


sed "s/,/<\/td><td>/g; s/^/<tr><td>/; s/$/<\/td><\/tr>/" "%INPUT%" >> "%OUTPUT%"

REM ---- start preformatted section ----
echo ^<pre^> >> "%OUTPUT%"

:: ---- awk SCAN SUMMARY section ----
::%gawk% "{
::    if ($0 ~ /SCAN SUMMARY/) start=1
::    if (start) print
::}" "%INPUTTEMP%" >> "%OUTPUT%"

:: ---- HTML footer ----
(
echo ^</pre^>
echo ^</table^>
echo ^</body^>
echo ^</html^>
) >> "%OUTPUT%"

:: ---- Cleanup ----
del "%INPUTTEMP%" >nul 2>&1

echo Manifest created: %OUTPUT%
endlocal
