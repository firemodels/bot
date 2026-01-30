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
%git_drive%
echo.

cd %userprofile%\.bundle\bundles

if "%platform%" == "windows" (
  echo   Viewing windows manifiest
  start explorer %fds_version%_%smv_version%_win_manifest.html
  goto eof
)
if "%platform%" == "linux" (
  echo   Viewing linux manifiest
  start explorer %fds_version%_%smv_version%_lnx_manifest.html
  goto eof
)
if "%platform%" == "osx" (
  echo   Viewing osx manifiest
  start explorer %fds_version%_%smv_version%_osx_manifest.html
  goto eof
)

:eof
echo.
echo installation complete
pause
