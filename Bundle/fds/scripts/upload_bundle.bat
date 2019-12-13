@echo off
setlocal

set fds_version_arg=%1
set smv_version_arg=%2
set nightly=%3
set upload_host=%4

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

if "%nightly%" == "null" goto endif2
  set nightly=_%nightly%
:endif2

set bundle_dir=%userprofile%\.bundle\bundles
set basename=%fds_version_arg%_%smv_version_arg%%nightly%_win
set bundlefile=%bundle_dir%\%basename%.exe
set bundleshafile=%bundle_dir%\%basename%.sha1

if EXIST %bundlefile% goto skip_upload
  echo ***Error: bundle file %basename%.exe does not exist in %bundle_dir%
  exit /b 1
:skip_upload

:: upload to linux computer
pscp %bundlefile%    %upload_host%:.bundle/bundles/.
pscp %bundleshafile% %upload_host%:.bundle/bundles/.

:: upload to google drive
plink %plink_options% %linux_logon% %linux_svn_root%/bot/Bundle/fds/scripts/upload_bundle.sh /home/gforney/.bundle/bundles %basename% tst win

exit /b 0