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

start chrome https://drive.google.com/drive/u/0/folders/0B_wB1pJL2bFQc1F4cjJWY2duWTA?resourcekey=0-J_yHat7iJoBp1fk6QS8gMA

call :uploadfile                %smv_revision%_lnx.sh     lnx sh
call :uploadfile                %smv_revision%_lnx.sha1   lnx sha1

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
