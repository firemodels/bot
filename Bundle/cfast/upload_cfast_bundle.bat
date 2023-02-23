@echo off
setlocal

set cfast_revision=CFAST7.7.4-34
set smv_revision=SMV6.7.21-1044
set nightly_arg=tst


set BUNDLEDIR=%userprofile%\.bundle\uploads
set basename=%cfast_revision%_%smv_revision%_tst_win
set fullfile=%BUNDLEDIR%\%basename%.exe
set plink_options=-no-antispoof

set configfile=%userprofile%\.bundle\bundle_config.bat
if not exist %configfile% echo ***error: %userprofile%\bundle_config.bat does not exist
if not exist %configfile% exit /b
call %configfile%
call check_config || exit /b 1

if NOT EXIST %fullfile% echo ***Error: bundle file %basename%.exe does not exist in %BUNDLEDIR%
if NOT EXIST %fullfile% exit /b 1

:: upload to linux computer
echo ***Uploading %fullfile% to %bundle_host%

pscp -P 22 %fullfile% %bundle_host%:.bundle/uploads/.

:: upload to google drive
echo plink %plink_options% %bundle_logon%@bundle_host% %bundle_root%/bot/Bundle/cfast/upload_cfast_bundle.sh .bundle/uploads %basename%
plink %plink_options% %bundle_logon%@%bundle_host% %bundle_root%/bot/Bundle/cfast/upload_cfast_bundle.sh .bundle/uploads %basename%

exit /b 0
