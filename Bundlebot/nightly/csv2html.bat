@echo off
setlocal EnableExtensions

set CDIR=%CD%
set bindir=..\..\scripts\bin
cd %bindir%
set bindir=%CD%
cd %CDIR%

cd temp
git clean -dxf 
set TEMPDIR=%CDIR%\temp
cd %CDIR%

:: ---- Input handling ----
if "%~1"=="" (
    echo Usage: %~nx0 inputfile
    exit /b 1
)

set "INPUT=%~1"
set "SUMMARYFILE=%TEMPDIR%\summary_%RANDOM%.txt"

set "TITLE=%~n1"
set "OUTPUT=%~1_manifest.html"

:: ---- extract summary portion of input file' ----
sed -n "/SCAN SUMMARY/,$ p" "%INPUT%" > "%SUMMARYFILE%" 

:: ---- HTML header ----
(
echo ^<html^>^<head^>^<title^>%TITLE% Manifest^</title^>^</head^>
echo ^<body^>
echo ^<h1^>%TITLE% Manifest^</h1^>
) > "%OUTPUT%"

:: ---- summary section ----
echo ^<pre^>       >> %OUTPUT%
type %SUMMARYFILE% >> %OUTPUT%
echo ^</pre^>      >> %OUTPUT%"

:: ---- beginning of table ----
(
echo ^<table border=on^>
echo ^<tr^>^<th^>file^</th^>^<th^>sha256 hash^</th^>^<th^>virus status^</th^>^</tr^>
) >> "%OUTPUT%"

:: body of table
sed "/SCAN SUMMARY/,$ d; s/^[^\\]*\\//; s/,/<\/td><td>/g; s/^/<tr><td>/; s/$/<\/td><\/tr>/" "%INPUT%" >> "%OUTPUT%"

:: ---- end of table ----
(
echo ^</table^>
) >> "%OUTPUT%"


:: ---- HTML footer ----
(
echo ^</pre^>
echo ^</body^>
echo ^</html^>
) >> "%OUTPUT%"

:: ---- Cleanup ----
del "%SUMMARYFILE%" >nul 2>&1

echo Manifest created: %OUTPUT%
endlocal
