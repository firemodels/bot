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

start chrome https://drive.google.com/drive/u/0/folders/0B_wB1pJL2bFQc1F4cjJWY2duWTA?resourcekey=0-J_yHat7iJoBp1fk6QS8gMA

call :uploadfile %uploaddir% %smv_revision%_win.exe    win exe
call :uploadfile %uploaddir% %smv_revision%_win.sha1   win sha1

echo.
echo upload complete
pause
goto eof

::---------------------------------------------
  :uploadfile
::---------------------------------------------

set FROMDIR=%1
set FROMFILE=%2
set PLATFORM=%3
set EXT=%4

if exist %FROMDIR%\%FROMFILE% goto else1
    echo "***error: %FROMFILE% was not found in %FROMDIR%"
    goto endif1
:else1
    cd %FROMDIR%
    echo uploading %FROMFILE% to %linux_hostname%
    pscp -P 22 %FROMFILE%    %linux_hostname%:.bundle/bundles/.
    plink %plink_options% %linux_logon%  %linux_svn_root%/bot/Bundlebot/upload_smvbundle.sh .bundle/bundles %FROMFILE% %PLATFORM% %EXT%
:endif1
exit /b

:eof
