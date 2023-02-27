@echo off

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo *** Error: This script is running as %username%.  It must run as Administrator.
    echo       Run again, after right clicking on this script and selecting "Run as Administrator"
    echo       CFAST uninstaller aborted.
    pause
    exit
)

echo.
echo *** Removing the association between .in and CEdit
assoc .in=       > Nul 2>&1
ftype ceditDoc=  > Nul 2>&1

set have_fds=1
where fds  > Nul 2>&1
if %errorlevel% == 1 set have_fds=0

if %have_fds% == 1 goto skip1
  echo.
  echo *** Removing the association between .smv and Smokeview
  assoc .smv=
  ftype smvDoc=
:skip1

echo. 
echo *** Removing cfast from the Start menu.
rmdir /q /s "%ProgramData%\Microsoft\Windows\Start Menu\Programs\CFAST7"

