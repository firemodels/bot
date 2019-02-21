@echo off
setlocal EnableDelayedExpansion
set platform=%1

:: batch file to install the FDS-SMV bundle on Windows, Linux or OSX systems

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
%svn_drive%
echo.

if "%platform%" == "windows" (
  echo.
  echo *** windows
  cd %svn_root%\bot\Bundle\fds\windows
  call copy_apps
  goto eof
)
if "%platform%" == "linux" (
  echo.
  echo *** linux
  plink %linux_logon% %linux_svn_root%/smv/scripts/run_command.sh bot/Firebot copy_apps.sh
  goto eof
)
if "%platform%" == "osx" (
  echo.
  echo *** osx
  plink %osx_logon% %linux_svn_root%/smv/scripts/run_command.sh bot/Firebot copy_apps.sh
  goto eof
)

:eof
echo.
echo copy complete
pause
