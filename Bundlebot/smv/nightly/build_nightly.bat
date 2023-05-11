@echo off

:: batch file for creating libraries on windows, linux or osx

set curdir=%CD%
cd ..\..\..\..
set reporoot=%CD%

cd %curdir%\output
set outdir=%CD%

cd %curdir%

echo -----------------------------------------------------------------------------
echo ---------------------- get smv repo revision --------------------------------
echo -----------------------------------------------------------------------------

call get_hash_revisions
set /p smv_hash=<output\SMV_HASH

echo -----------------------------------------------------------------------------
echo ---------------------- get clone smv repo ---------------------------------
echo -----------------------------------------------------------------------------

call clone_repos %smv_hash%
cd %reporoot%\smv
git describe --abbrev-7 --long --dirty > %outdir%\smvrepo_revision
set /p smvrepo_revision=<%outdir%\smvrepo_revision


:: setup compiler environment
if x%setup_intel% == x1 goto skip1
set setup_intel=1
call %reporoot%\smv\Utilities\Scripts\setup_intel_compilers.bat
:skip1


:: build libraries
title building libraries
echo building libraries
cd %reporoot%\smv\Build\LIBS\intel_win_64
call make_LIBS bot

echo.
echo  Building applications
Title Building applications

%svn_drive%

set "progs=background flush hashfile smokediff smokezip wind2fds"

for %%x in ( %progs% ) do (
  title Building %%x
  cd %reporoot%\smv\Build\%%x\intel_win_64
    echo.
  echo -----------------------------------------------------------------------------
  echo ---------------------- building %%x -----------------------------------------
  echo -----------------------------------------------------------------------------
  make -j 4 SHELL="%ComSpec%" -f ..\Makefile intel_win_64
) 

echo.
echo -----------------------------------------------------------------------------
echo ---------------------- building smokeview -----------------------------------------
echo -----------------------------------------------------------------------------
cd %reporoot%\smv\Build\smokeview\intel_win_64
title Building smokeview
call make_smokeview -bot

echo.
echo -----------------------------------------------------------------------------
echo ---------------------- Building Smokeview bundle -----------------------------------------
echo -----------------------------------------------------------------------------
echo.
Title Building Smokeview bundle

call %reporoot%\bot\Bundlebot\smv\scripts\make_testbundle %smvrepo_revision%

echo.
echo -----------------------------------------------------------------------------
echo ---------------------- Uploading Smokeview bundle -----------------------------------------
echo -----------------------------------------------------------------------------
echo.
Title Building Smokeview bundle

set uploaddir=%userprofile%\.bundle\uploads

set filelist=%TEMP%\smv_files_win.out
gh release view %GH_SMOKEVIEW_TAG%  -R github.com/%GH_OWNER%/%GH_REPO% | grep SMV | grep -v FDS | grep -v CFAST | grep win | gawk "{print $2}" > %filelist%
for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset %GH_SMOKEVIEW_TAG% %%A  -R github.com/%GH_OWNER%/%GH_REPO% -y
erase %filelist%

gh release upload %GH_SMOKEVIEW_TAG% %uploaddir%\%smvrepo_revision%_win.sha1 -R github.com/%GH_OWNER%/%GH_REPO% --clobber
gh release upload %GH_SMOKEVIEW_TAG% %uploaddir%\%smvrepo_revision%_win.exe  -R github.com/%GH_OWNER%/%GH_REPO% --clobber

echo.
echo upload complete

cd %curdir%
