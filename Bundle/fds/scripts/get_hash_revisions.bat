@echo off

::set firebot_home=~firebot
set firebot_home=/home2/smokevis2/firebot
set firebot_host=blaze.el.nist.gov
set SHOWPARMS=0
call :getopts %*

if "%SHOWPARMS%" == "1" (
  echo firebot_host=%firebot_host%
  echo firebot_home=%firebot_home%
  exit /b
)

pscp  %firebot_host%:%firebot_home%/.firebot/apps/FDS_HASH    output\FDS_HASH > Nul
pscp  %firebot_host%:%firebot_home%/.firebot/apps/SMV_HASH    output\SMV_HASH > Nul
pscp  %firebot_host%:%firebot_home%/.firebot/apps/FDS_REVISION output\FDS_REVISION > Nul
pscp  %firebot_host%:%firebot_home%/.firebot/apps/SMV_REVISION output\SMV_REVISION > Nul
goto eof


::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------

:getopts
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-g" (
   shift
   set firebot_host=%1
   set valid=1
 )
 if /I "%1" EQU "-G" (
   shift
   set firebot_home=%1
   set valid=1
 )
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "-v" (
   set SHOWPARMS=1
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
   exit /b
 )
if not (%1)==() goto getopts
exit /b

::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo This script outputs an fds or smv repo hash
echo.
echo Options:
echo -g - host where firebot was run
echo -G - home directory where firebot was run
echo -h - display this message
echo -v - show parameters used to build bundle (the bundle is not generated)
exit /b

:eof

exit /b
