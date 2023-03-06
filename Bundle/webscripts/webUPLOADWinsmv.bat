@echo off

::  batch file to build test or release Smokeview on a Windows, OSX or Linux system

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

%svn_drive%
call %envfile%

set uploaddir=%userprofile%\.bundle\uploads
set CURDIR=%CD%

start chrome https://github.com/gforney/night_bundle/releases/tag/TEST_BUNDLES

cd %svn_root%\night_bundle
gh release upload TEST_BUNDLES %uploaddir%\%smv_revision%_win.sha1 --clobber
gh release upload TEST_BUNDLES %uploaddir%\%smv_revision%_win.exe  --clobber

echo.
echo upload complete
pause

:eof
