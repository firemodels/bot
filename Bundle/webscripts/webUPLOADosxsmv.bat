@echo off

set RELEASEREPO=test_bundles
set RELEASEBRANCH=TEST

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

cd %svn_root%\%RELEASEREPO%

set outfile=%TEMP%\files_osx.out
gh release view %RELEASEBRANCH% | grep SMV | grep -v FDS | grep -v CFAST | grep osx | gawk "{print $2}" > %outfile%
for /F "tokens=*" %%A in (%outfile%) do gh release delete-asset %RELEASEBRANCH% %%A -y
erase %outfile%

plink %plink_options% %linux_logon%  %linux_svn_root%/bot/Bundlebot/upload_smvbundle.sh .bundle/uploads %smv_revision%_osx.sh   %linux_svn_root%/%RELEASEREPO% %RELEASEBRANCH%
plink %plink_options% %linux_logon%  %linux_svn_root%/bot/Bundlebot/upload_smvbundle.sh .bundle/uploads %smv_revision%_osx.sha1 %linux_svn_root%/%RELEASEREPO% %RELEASEBRANCH%

start chrome https://github.com/firemodels/%RELEASEREPO%/releases/tag/%RELEASEBRANCH%

echo.
echo upload complete
pause
