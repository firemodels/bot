@echo off
setlocal

set S_HASH=
set S_REVISION=
set S_BRANCH=

::set S_HASH=2f257722a
::set S_REVISION=SMV-6.10.5-249
::set S_BRANCH=size64

set upload_smvbundle=
::*** parse command line arguments
call :getopts %*

set OWNER=firemodels
::set OWNER=%username%

if not exist %userprofile%\.bundle mkdir %userprofile%\.bundle
set CURDIR=%CD%

cd %CURDIR%\output
set outdir=%CD%
cd %CURDIR%

cd ..\..\..
set reporoot=%CD%
cd %CURDIR%
set gawk=%reporoot%\bot\scripts\bin\gawk.exe

call get_smv_hash_revisions %S_HASH% %S_REVISION% > %outdir%\stage1_hash 2>&1
set /p smv_hash=<%outdir%\SMV_HASH

echo *** cloning smv repo
call clone_smv_repo %smv_hash%  %S_BRANCH% > %outdir%\stage2_clone 2>&1

cd %reporoot%\smv
git describe --abbrev=7 --long --dirty > %outdir%\smvrepo_revision
set /p smvrepo_revision=<%outdir%\smvrepo_revision
set BUNDLE_SMV_TAG=%smvrepo_revision%
echo ***     smv hash: %smv_hash%
echo *** smv revision: %smvrepo_revision%
echo.

:: setup compiler environment
if x%setup_intel% == x1 goto skip1
echo *** defining compiler environment
set setup_intel=1
call %reporoot%\smv\Utilities\Scripts\setup_intel_compilers.bat > %outdir%\stage2_compiler_setup 2>&1
:skip1

:: build libraries
title building libraries
echo *** building libraries
cd %reporoot%\smv\Build\LIBS\intel_win
call make_LIBS bot > %outdir%\stage3_LIBS 2>&1

echo *** Building applications
Title Building applications

set "progs=background flush smokediff pnginfo smokezip fds2fed wind2fds set_path timep get_time sh2bat"

for %%x in ( %progs% ) do (
  title Building %%x
  cd %reporoot%\smv\Build\%%x\intel_win
  echo *** building %%x
  make -j 4 SHELL="%ComSpec%" -f ..\Makefile intel_win > %outdir%\stage4_%%x 2>&1
) 

echo *** building smokeview
cd %reporoot%\smv\Build\smokeview\intel_win
title Building smokeview
call make_smokeview -bot > %outdir%\stage5_smokeview 2>&1

echo *** bundling smokeview
Title Building Smokeview bundle

cd %CURDIR%\..\release
call make_smv_bundle %BUNDLE_SMV_TAG%

cd %CURDIR%

set uploaddir=%userprofile%\.bundle\bundles
echo smokeview bundle created: %uploaddir%\%smvrepo_revision%_win.exe

if "x%upload_smvbundle%" == "x" goto skip_upload
echo *** uploading Smokeview bundle
Title Building Smokeview bundle

set filelist=%TEMP%\smv_files_win.out
gh release view SMOKEVIEW_TEST  -R github.com/%OWNER%/test_bundles | grep SMV | grep -v FDS | grep -v CFAST | grep win | %gawk% "{print $2}" > %filelist%
for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset SMOKEVIEW_TEST %%A  -R github.com/%OWNER%/test_bundles -y
erase %filelist%

echo uploading %smvrepo_revision%_win.exe to github.com//%OWNER%/test_bundles
gh release upload SMOKEVIEW_TEST %uploaddir%\%smvrepo_revision%_win.exe  -R github.com/%OWNER%/test_bundles --clobber

echo uploading %smvrepo_revision%_win_manifest.html to github.com//%OWNER%/test_bundles
gh release upload SMOKEVIEW_TEST %uploaddir%\%smvrepo_revision%_win_manifest.html  -R github.com/%OWNER%/test_bundles --clobber

echo *** upload complete
:skip_upload

goto eof


::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo BuildSmvNightly usage
echo.
echo Options:
echo -h - display this message
echo -U - upload bundle
exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 
 if "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if "%1" EQU "-U" (
   set upload_smvbundle=1
   set valid=1
 )
 shift
 if %valid% == 0 (
   echo.
   echo ***Error: the input argument %arg% is invalid
   echo.
   echo Usage:
   call :usage
   set stopscript=1
   exit /b 1
 )
if not (%1)==() goto getopts
exit /b 0

:eof
