@echo off
call BUILD_config
set BUNDLE_SMV_TAG=SMV-6.9.0test


set basename=%BUNDLE_SMV_TAG%_win
set fullfilebase=%userprofile%\.bundle\uploads\%basename%

set GH_SMV_TAG=SMOKEVIEW_TEST2

:: clone smv repo
call clone_smv_repo  %BUNDLE_SMV_REVISION% release %BUNDLE_SMV_TAG%

:: build apps
call make_smv_apps

:: make bundle
call make_smv_bundle %BUNDLE_SMV_TAG%

:: upload bundles
echo uploading %fullfilebase%.sha1
gh release upload %GH_SMV_TAG% %fullfilebase%.sha1 -R github.com/%GH_OWNER%/%GH_REPO% --clobber

echo uploading %fullfilebase%.exe
gh release upload %GH_SMV_TAG% %fullfilebase%.exe  -R github.com/%GH_OWNER%/%GH_REPO% --clobber

