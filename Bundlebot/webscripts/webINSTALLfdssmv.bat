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

if "%platform%" == "windows" (
  echo   Installing FDS and Smokeview
  Title  Installing FDS and Smokeview
  cd %userprofile%\.bundle\bundles
  call %fds_version%_%smv_version%_win.exe
  goto eof
)
if "%platform%" == "linux" (
echo   Installing FDS and Smokeview on %platform%
Title  Installing FDS and Smokeview on %platform%
  plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command2.sh .bundle/bundles %fds_version%_%smv_version%_lnx.sh y
  goto eof
)
if "%platform%" == "osx" (
echo   Installing FDS and Smokeview on %platform%
Title  Installing FDS and Smokeview on %platform%
  plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command2.sh .bundle/bundles %fds_version%_%smv_version%_osx.sh y
  goto eof
)

:eof
echo.
echo installation complete
pause
