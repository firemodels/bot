@echo off
setlocal

set "BUNDLEDIR=%userprofile%\Google Drive\nightly_bundles\"

set smv_version_arg=%1
set nightly_arg=%2
set upload_host=%3

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
echo.

if NOT "%upload_host%" == "null" goto endif1
  set upload_host=blaze.el.nist.gov
:endif1

set nightly=
if "%nightly_arg%" == "null" goto endif2
  set nightly=_%nightly_arg%
:endif2

set GOOGLE_DIR=
if NOT "%nightly_arg%" == "null" goto endif3
  set nightly=_rls
  set GOOGLE_DIR=release_dir
:endif3

if NOT "%nightly_arg%" == "rls" goto endif3
  set nightly=_rls
  set GOOGLE_DIR=release_dir
:endif3

set bundle_dir=%userprofile%\.bundle\bundles
set basename=%smv_version_arg%%nightly%_win

set bundlefile=%bundle_dir%\%basename%.exe
set bundleshafile=%bundle_dir%\%basename%.sha1

if EXIST %bundlefile% goto skip_upload
  echo ***Error: bundle file %basename%.exe does not exist in %bundle_dir%
  exit /b 1
:skip_upload

if NOT EXIST "%BUNDLEDIR%" goto if_bundledir
  erase "%BUNDLEDIR%"\*tst_win.exe  1> Nul 2>&1
  erase "%BUNDLEDIR%"\*tst_win.sha1 1> Nul 2>&1

  copy %bundlefile%    "%BUNDLEDIR%\%basename%.exe"
  copy %bundleshafile% "%BUNDLEDIR%\%basename%.sha1"
  exit /b 0
:if_bundledir

:: upload to linux computer
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo uploading %bundlefile% to %upload_host%
echo.

pscp -P 22 %bundlefile%    %upload_host%:.bundle/bundles/.

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo uploading %bundleshafile% to %upload_host%
echo.

pscp -P 22 %bundleshafile% %upload_host%:.bundle/bundles/.

:: upload to google drive
plink %plink_options% %linux_logon% %linux_svn_root%/bot/Bundlebot/upload_bundle.sh $HOME/.bundle/bundles %basename% %nightly_arg% win %GOOGLE_DIR%

exit /b 0
