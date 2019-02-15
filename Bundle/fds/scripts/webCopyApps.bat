@echo off
setlocal EnableDelayedExpansion
set platform=%1
set program=%2

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
  cd %svn_root%\bot\Bundle\fds\scripts
  call copy_apps %program%
  goto eof
)
if "%platform%" == "linux" (
  plink %linux_logon% %linux_svn_root%/smv/scripts/run_command.sh bot/Bundle/fds/scripts copy_apps.sh %program%
  goto eof
)
if "%platform%" == "osx" (
  plink %osx_logon% %linux_svn_root%/smv/scripts/run_command.sh bot/Bundle/fds/scripts copy_apps.sh %program%
  goto eof
)

:eof
echo.
echo copy complete
pause
