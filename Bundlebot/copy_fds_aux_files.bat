@echo off
set FROMBASEDIR=%1
set TOBASEDIR=%2

call :copy_file Fires upholstery_matl.tpl
call :copy_file Fires gypsum_walls.tpl
call :copy_file Fires couch2_devices.dat
goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set FROMDIR=%1
set FROMFILE=%2

set error==0
if exist "%FROMBASEDIR%" goto if1
  echo ***Error: source base directory %FROMBASEDIR% does not exist
  set error=1
:if1
if exist "%TOBASEDIR%" goto if2
  echo ***Error: destination base directory %TOBASEDIR% does not exist
  set error=1
:if2
if exist "%FROMBASEDIR%\%FROMDIR%\%FROMFILE%" goto if3
  echo ***Error: the file %FROMFILE% does not exist in %FROMBASEDIR%\%FROMDIR%
  set error=1
:if3
if exist "%TOBASEDIR%\%FROMDIR%" goto if4
  echo ***Error: the destination directory %TOBASEDIR%\%FROMDIR% does not exist
  set error=1
:if4
if "%error%"  == "1" exit /b 0

echo        copying: %FROMFILE% to %TOBASEDIR%\%FROMDIR%
copy %FROMBASEDIR%\%FROMDIR%\%FROMFILE% %TOBASEDIR%\%FROMDIR%\%FROMFILE%>Nul
exit /b 1

:eof
exit /b 1
