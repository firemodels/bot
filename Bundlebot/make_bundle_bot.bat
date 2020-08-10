@echo off
set bot_host=%1
set bot_home=%2
set branch=%3

set curdir=%CD%

cd ..\..\..\..\bot
set botrepo=%CD%

cd %botrepo%\Scripts
call setup_repos -T -n

cd %curdir%

:: get fds hash of lastest successful firebot run

pscp -P 22 %bot_host%:%bot_home%/.firebot/apps/FDS_HASH fds_hash
set /p fds_hash=<fds_hash
cd ..\..\..\..\fds
set fdsrepo=%CD%
git checkout -b %branch% %fds_hash%
git describe --dirty --long | gawk -F"-" "{print $1\"-\"$2}" > fds_version
set /p fds_version=<fds_version
cd %curdir%

:: get smv hash of lastest successful firebot run

pscp -P 22 %bot_host%:%bot_home%/.firebot/apps/SMV_HASH smv_hash
set /p smv_hash=<smv_hash
cd ..\..\..\..\smv
set smvrepo=%CD%
git checkout -b %branch% %smv_hash%
git describe --dirty --long | gawk -F"-" "{print $1\"-\"$2}" > smv_version
set /p smv_version=<smv_version
cd %curdir%

echo fds_version=%fds_version%
echo smv_version=%smv_version%
pause

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

