@echo off
setlocal EnableDelayedExpansion
set platform=%1

:: batch file to copy FDS-SMV bundles to a google drive directory

:: setup environment variables (defining where repository resides etc) 

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
pause>NUL
goto:eof

:endif_envexist

call %envfile%
%git_drive%
echo.

set uploaddir=%userprofile%\.bundle\bundles
set "googledir=%userprofile%\Google Drive\Bundle_Test_Versions\"

if NOT exist "%googledir%\*" goto error

call :copyfile %uploaddir% %fds_version%_%smv_version%_win.exe      "%googledir%"
call :copyfile %uploaddir% %fds_version%_%smv_version%_lnx.sh       "%googledir%"
call :copyfile %uploaddir% %fds_version%_%smv_version%_osx.sh       "%googledir%"

echo.
echo copy complete
pause
goto eof


::---------------------------------------------
  :copyfile
::---------------------------------------------

set FROMDIR=%1
set FROMFILE=%2
set TODIR=%3

if exist %FROMDIR%\%FROMFILE% goto else1
    echo "***error: %FROMFILE% was not found in %FROMDIR%"
    goto endif1
:else1
    copy /Y %FROMDIR%\%FROMFILE% %TODIR% > Nul 2> Nul
    if NOT exist %TODIR%\%FROMFILE% goto else2
      echo %FROMFILE% copied to %TODIR%\%TOFILE%
      goto endif2
:else2
      echo ***error: %FROMFILE% could not be copied to %TODIR%
:endif2
:endif1
exit /b

:error

echo ***warning: The directory %googledir% does not exist.  copy aborted
pause
:eof

