@echo off
call config

:: uncomment and edit the following lines if building a test bundle.
:: otherwise use settings in config.bat.
::set BUNDLE_SMV_HASH=9ce553208
::set BUNDLE_SMV_TAG=SMV-6.9.1test

set scan_bundle=1


set basename=%BUNDLE_SMV_TAG%_win
set fullfilebase=%userprofile%\.bundle\bundles\%basename%
set CURDIR=%CD%
set OUTDIR=%CURDIR%\output

cd ..\..\..
set GITROOT=%CD%
cd %CURDIR%

:: update web repo
if NOT exist ..\..\..\webpages echo *** error webpages repos does not exist
if NOT exist ..\..\..\webpages exit /b
cd ..\..\..\webpages
git remote update
git merge origin/nist-pages
cd %CURDIR%


:: clone smv repo
call clone_smv_repo  %BUNDLE_SMV_HASH% release %BUNDLE_SMV_TAG%

:: build apps
set progs=LIBS flush smokediff pnginfo smokezip fds2fed wind2fds set_path timep get_time smokeview
for %%x in ( %progs% ) do (
  cd %GITROOT%\smv\Build\%%x\intel_win
  echo *** building %%x
  call make_%%x > %OUTDIR%\stage4_%%x 2>&1
) 

:: make bundle
cd %CURDIR%
call make_smv_bundle %BUNDLE_SMV_TAG% %scan_bundle%

:: upload bundles

echo uploading %fullfilebase%.exe
gh release upload SMOKEVIEW_TEST %fullfilebase%.exe  -R github.com/%username%/test_bundles --clobber
echo uploading %fullfilebase%_manifest.html
gh release upload SMOKEVIEW_TEST %fullfilebase%_manifest.html  -R github.com/%username%/test_bundles --clobber

