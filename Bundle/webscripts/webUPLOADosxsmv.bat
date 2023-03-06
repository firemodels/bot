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
set release_repo=%linux_svn_root%/night_bundle
set CURDIR=%CD%

start chrome https://github.com/gforney/night_bundle/releases/tag/TEST_BUNDLES

call :uploadfile                %smv_revision%_osx.sh     osx sh
call :uploadfile                %smv_revision%_osx.sha1   osx sha1

echo.
echo upload complete
pause
goto eof

::---------------------------------------------
  :uploadfile
::---------------------------------------------

set FROMFILE=%1
set PLATFORM=%2
set EXT=%3

plink %plink_options% %linux_logon%  %linux_svn_root%/bot/Bundlebot/upload_smvbundle.sh .bundle/uploads %FROMFILE% %PLATFORM% %EXT% %release_repo%
exit /b

:eof
