@echo off
set bot_host=%1
set bothome=%2

set curdir=%CD%

:: get fds hash of lastest successful firebot run

pscp %bothost:%bothome/.firebot/history/fdshash fdshash
set /p fdshash=<fdshash
cd ..\..\..\..\fds
set fdsrepo=%CD%
git checkout %fdshash%
git describe --dirty --long > fds_version
set /p fds_version=<fds_version
cd %curdir%

:: get smv hash of lastest successful firebot run

pscp %bothost:%bothome/.firebot/history/smvhash smvhash
set /p smvhash=<smvhash
cd ..\..\..\..\smv
set smvrepo=%CD%
git checkout %smvhash%
git describe --dirty --long > smv_version
set /p smv_version=<smv_version
cd %curdir%

call make_fds.bat
cd %fdsrepo%
git checkout master

call make_smv.bat
cd %smvrepo%
git checkout master

call copy_apps fds
call copy_apps smv
call copy_pubs firebot  .firebot/pubs  %bot_host%
call copy_pubs smokebot .smokebot/pubs %bot_host%

call make_bundle

