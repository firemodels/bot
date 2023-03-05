@echo off
setlocal

set cfast_revision=%1
set smv_revision=%2
set upload=%3%
set nightly_arg=tst

if %upload% == 0 exit /b

set BUNDLEDIR=%userprofile%\.bundle\uploads
set basename=%cfast_revision%_%smv_revision%_tst_win
set fullfile=%BUNDLEDIR%\%basename%.exe

set configfile=%userprofile%\.bundle\bundle_config.bat
if not exist %configfile% echo ***error: %userprofile%\bundle_config.bat does not exist
if not exist %configfile% exit /b
call %configfile%
call check_config || exit /b 1

if NOT EXIST %fullfile% echo ***Error: bundle file %basename%.exe does not exist in %BUNDLEDIR%
if NOT EXIST %fullfile% exit /b 1

echo ***Uploading %fullfile% to GitHub

set CURDIR=%CD%

cd ..\..\Scripts
set SCRIPTDIR=%CD%

cd %CURDIR%\

cd ..\..\..\cftest

echo *** Deleting tag: CFTEST
call %SCRIPTDIR%\delete_release -t CFTEST

echo *** Adding release: tag: CFTEST title: %cfast_revision%_%smv_revision%
call %SCRIPTDIR%\add_release -t CFTEST -T %cfast_revision%_%smv_revision% -f %fullfile%

cd %CURDIR%
exit /b 0
