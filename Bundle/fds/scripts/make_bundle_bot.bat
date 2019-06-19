@echo off
set bot_host=%1
set bot_home=%2

set curdir=%CD%

:: get fds hash of lastest successful firebot run

pscp %bot_host%:%bot_home%/.firebot/history/fds_hash fds_hash
set /p fds_hash=<fds_hash
cd ..\..\..\..\fds
set fdsrepo=%CD%
git checkout %fds_hash%
git describe --dirty --long > fds_version
set /p fds_version=<fds_version
cd %curdir%

:: get smv hash of lastest successful firebot run

pscp %bot_host%:%bot_home%/.firebot/history/smv_hash smv_hash
set /p smv_hash=<smv_hash
cd ..\..\..\..\smv
set smvrepo=%CD%
git checkout %smv_hash%
git describe --dirty --long > smv_version
set /p smv_version=<smv_version
cd %curdir%

call make_fds_progs.bat
cd %fdsrepo%
git checkout master

call make_smv_progs.bat
cd %smvrepo%
git checkout master

call copy_apps firebot
call copy_apps smokebot
call copy_pubs firebot  .firebot/pubs  %bot_host%
call copy_pubs smokebot .smokebot/pubs %bot_host%

call make_bundle

