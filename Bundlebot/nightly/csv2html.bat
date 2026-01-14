@echo off
setlocal EnableExtensions

REM ---- Input handling ----
if "%~1"=="" (
    echo Usage: %~nx0 inputfile
    exit /b 1
)

set "INPUT=%~1"
set "INPUTTEMP=%INPUT%.%RANDOM%"
set "TITLE=%~n1"
set "OUTPUT=%~n1_manifest.html"

REM ---- sed replacement (same as Bash) ----
sed "s/: OK/OK/g" "%INPUT%" > "%INPUTTEMP%"

REM ---- HTML header ----
(
echo ^<html^>^<head^>^<title^>%TITLE% Manifest^</title^>^</head^>
echo ^<body^>
echo ^<h1^>%TITLE% Manifest^</h1^>
echo ^<table border=on^>
echo ^<tr^>^<th^>file^</th^>^<th^>sha256 hash^</th^>^<th^>virus status^</th^>^</tr^>
) > "%OUTPUT%"

REM ---- awk table rows (until SCAN SUMMARY) ----
awk -F, "{
    if ($0 ~ /SCAN SUMMARY/) exit
    printf \"<tr>\"
    for (i=1; i<=NF; i++) printf \"<td>%s</td>\", $i
    print \"</tr>\"
}" "%INPUTTEMP%" >> "%OUTPUT%"

REM ---- start preformatted section ----
echo ^<pre^> >> "%OUTPUT%"

REM ---- awk SCAN SUMMARY section ----
awk "{
    if ($0 ~ /SCAN SUMMARY/) start=1
    if (start) print
}" "%INPUTTEMP%" >> "%OUTPUT%"

REM ---- HTML footer ----
(
echo ^</pre^>
echo ^</table^>
echo ^</body^>
echo ^</html^>
) >> "%OUTPUT%"

REM ---- Cleanup ----
del "%INPUTTEMP%" >nul 2>&1

echo Manifest created: %OUTPUT%
endlocal
