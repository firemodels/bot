@echo off
setlocal

set cfast_revision=%1
set smv_revision=%2
set cfast_revision=CFAST7.7.4-31
set smv_revision=SMV6.7.21-1044
set nightly_arg=tst


set BUNDLEDIR=%userprofile%\.bundle\uploads
set upload_host=blaze.el.nist.gov
set basename=%cfast_revision%_%smv_revision%_tst_win
set fullfile=%BUNDLEDIR%\%basename%.exe

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

if NOT EXIST %fullfile% echo ***Error: bundle file %basename%.exe does not exist in %BUNDLEDIR%
if NOT EXIST %fullfile% exit /b 1

:: upload to linux computer
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo uploading %bundlefile% to %upload_host%
echo.

pscp -P 22 %fullfile% %upload_host%:.bundle/uploads/.

:: upload to google drive
plink %plink_options% %linux_logon% %linux_svn_root%/bot/Bundle/cfast/upload_cfast_bundle.sh .bundle/uploads %basename%

exit /b 0
