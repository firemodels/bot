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

set filelist=%TEMP%\cfast_smv_files_win.out
gh release view %GH_CFAST_TAG% -R github.com/%GH_OWNER%/%GH_REPO% | grep CFAST | grep SMV | grep win | gawk "{print $2}" > %filelist%
for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset %GH_CFAST_TAG% %%A -R github.com/%GH_OWNER%/%GH_REPO% -y
erase %filelist%

gh release upload %GH_CFAST_TAG% %fullfile% --clobber -R github.com/%GH_OWNER%/%GH_REPO%

cd %CURDIR%\..\..\Bundlebot\scripts
call setreleasetitle cfast

cd %CURDIR%
exit /b 0
