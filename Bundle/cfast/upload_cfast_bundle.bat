@echo off
setlocal

set cfast_revision=%1
set smv_revision=%2
set upload=%3%
set nightly_arg=test

if %upload% == 0 exit /b

set BUNDLEDIR=%userprofile%\.bundle\uploads
set basename=%cfast_revision%_%smv_revision%_test_win
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

cd ..\..\..\%GH_REPO%
gh repo set-default %GH_OWNER%/%GH_REPO%

set RELEASEBRANCH=TEST
set filelist=%TEMP%\cfast_smv_files_win.out
gh release view %RELEASEBRANCH% | grep CFAST | grep SMV | grep win | gawk "{print $2}" > %filelist%
for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset %RELEASEBRANCH% %%A -y
erase %filelist%

gh release upload %GH_CFAST_TAG% %fullfile% --clobber

cd %CURDIR%
exit /b 0
