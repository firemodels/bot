@echo off
set case=%1
set mypath=%~dp0

call :is_file_installed gprof || exit /b 1
if exist "%mypath%\smokeview_gnu.exe" gprof "%mypath%\smokeview_gnu.exe" > %case%_profile.txt
if exist "%mypath%\smokeview_gnu.exe" echo profile information outputted to %case%_profile.txt
if exist "%mypath%\smokeview_gnu.exe" exit /b 0
echo ***error: cannot profile smokeview_gnu.exe
echo %mypath%\smokeview_gnu.exe does not exist
exit /b 1

:: -------------------------------------------------------------
:is_file_installed
:: -------------------------------------------------------------

  set program=%1
  set exist=%TEMP%\exist.txt
  set count=%TEMP%\count.txt
  %program% --help 1>> %exist% 2>&1
  type %exist% | find /i /c "not recognized" > %count%
  set /p nothave=<%count%
  if %nothave% == 1 (
    echo "***Fatal error: %program% not present"
    erase %exist%
    erase %count%
    exit /b 1
  )
  erase %exist%
  erase %count%
  exit /b 0
