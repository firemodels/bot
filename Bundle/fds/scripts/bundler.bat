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

call clone_repos || exit /b 1

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
call make_bundle bot
