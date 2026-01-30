@echo off
setlocal EnableDelayedExpansion

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
%git_drive%
echo.

echo *** windows
echo cleaning "%userprofile%\.bundle\bundles"
cd "%userprofile%\.bundle"
rmdir /q /s bundles
mkdir bundles

echo.
echo *** linux
plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command.sh bot/Bundlebot/fds/scripts clean_upload.sh

echo.
echo *** osx
plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command.sh bot/Bundlebot/fds/scripts clean_upload.sh

echo.
pause
