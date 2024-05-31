@echo off
call config

:: uncomment and edit the following lines if building a test bundle.
:: otherwise use settings in config.bat.
::set BUNDLE_SMV_REVISION=9ce553208
::set BUNDLE_SMV_TAG=SMV-6.9.1test


set basename=%BUNDLE_SMV_TAG%_win
set fullfilebase=%userprofile%\.bundle\uploads\%basename%

:: clone smv repo
call clone_smv_repo  %BUNDLE_SMV_REVISION% release %BUNDLE_SMV_TAG%

:: build apps
call make_smv_apps

:: make bundle
call make_smv_bundle %BUNDLE_SMV_TAG%

:: upload bundles
echo uploading %fullfilebase%.sha1
gh release upload SMOKEVIEW_TEST %fullfilebase%.sha1 -R github.com/%username%/test_bundles --clobber

echo uploading %fullfilebase%.exe
gh release upload SMOKEVIEW_TEST %fullfilebase%.exe  -R github.com/%username%/test_bundles --clobber

