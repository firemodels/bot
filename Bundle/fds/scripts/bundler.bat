@echo off
set hostname=%1
set firebot_home=%2
set smokebot_home=%3

if "x%hostname%" == "x" (
  set hostname=blaze.el.nist.gov
)
if "x%firebot_home%" == "x" (
  set firebot_home=/home2/smokevis2/firebot
)
if "x%smokebot_home%" == "x" (
  set smokebot_home=/home2/smokevis2/smokebot
)

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
call make_bundle bot %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% 

cd %CURDIR%
call upload_bundle %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER%