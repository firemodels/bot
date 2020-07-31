@echo off
set clone=%1
set hostname=%2
set firebot_home=%3
set smokebot_home=%4

if EXIST .bundlebot goto endif1
  echo ***error: run_bundlebot.bat must be run in bot/Bundlebot directory
  exit /b 1
:endif1

if "x%clone%" == "xclone" goto endif2
  echo ***error:  this script clones (ie erases) the fds and smv repos.  
  echo            clone must be specified as the first argument to use this script
  exit /b 1
:endif2

if "x%hostname%" == "x" (
  set hostname=blaze.el.nist.gov
)
if "x%firebot_home%" == "x" (
  set firebot_home=/home2/smokevis2/firebot
)
if "x%smokebot_home%" == "x" (
  set smokebot_home=/home2/smokevis2/smokebot
)
set nightly=tst

set CURDIR=%CD%

call get_hash_revisions.bat || exit /b 1

set /p FDS_HASH_BUNDLER=<output\FDS_HASH
set /p SMV_HASH_BUNDLER=<output\SMV_HASH
set /p FDS_REVISION_BUNDLER=<output\FDS_REVISION
set /p SMV_REVISION_BUNDLER=<output\SMV_REVISION

erase output\FDS_HASH
erase output\SMV_HASH
erase output\FDS_REVISION
erase output\SMV_REVISION

cd %CURDIR%

echo.
echo cloning fds and smv repos using:
echo FDS REVISION=%FDS_REVISION_BUNDLER%, FDS HASH=%FDS_HASH_BUNDLER% 
echo SMV REVISION=%SMV_REVISION_BUNDLER%, SMV HASH=%SMV_HASH_BUNDLER% 
echo.

call clone_repos %FDS_HASH_BUNDLER% %SMV_HASH_BUNDLER% || exit /b 1

cd %CURDIR%
call make_apps   || exit /b 1

cd %CURDIR%
call copy_apps fds bot || exit /b 1

cd %CURDIR%
call copy_apps smv bot || exit /b 1

cd %CURDIR%
call copy_pubs firebot  %firebot_home%/.firebot/pubs   %hostname% || exit /b 1

cd %CURDIR%
call copy_pubs smokebot %smokebot_home%/.smokebot/pubs %hostname% || exit /b 1

cd %CURDIR%
call make_bundle bot %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% %nightly%

cd %CURDIR%
call upload_bundle %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% %nightly% %hostname% || exit /b 1

exit /b 0
