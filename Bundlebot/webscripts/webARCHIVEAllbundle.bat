@echo off
setlocal EnableDelayedExpansion

set upload_dir=%userprofile%\.bundle\bundles

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
set env_defined=1

set version=%smv_revision%

echo.
echo   Archiving Smokeview for Linux and OSX
Title  Archiving Smokeview for Linux and OSX

%git_drive%

plink %plink_options% %linux_logon% %linux_git_root%/bot/Bundlebot/smv/scripts/archive_bundle.sh %version%_lnx
plink %plink_options% %osx_logon% %linux_git_root%/bot/Bundlebot/smv/scripts/archive_bundle.sh %version%_osx

:eof
echo.
echo archive complete
pause
