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

set filelist=%TEMP%\smv_files_win.out
gh release view %RELEASEBRANCH% | grep SMV | grep -v FDS | grep -v CFAST | grep win | gawk "{print $2}" > %filelist%
for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset %RELEASEBRANCH% %%A -y
erase %filelist%

gh release upload %RELEASEBRANCH% %uploaddir%\%smv_revision%_win.sha1 --clobber
gh release upload %RELEASEBRANCH% %uploaddir%\%smv_revision%_win.exe  --clobber

start chrome https://github.com/firemodels/%RELEASEREPO%/releases/tag/%RELEASEBRANCH%
echo.
echo upload complete
pause

:eof
