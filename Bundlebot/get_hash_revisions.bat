@echo off
set error=0

::set firebot_home=~firebot
set firebot_home=/home2/smokevis2/firebot
set firebot_host=blaze.el.nist.gov
set "HASHDIR=%userprofile%\Google Drive\FDS-SMV Newest Manuals\HASHES"
set SHOWPARMS=0

call :getopts %*

if "%SHOWPARMS%" == "1" (
  echo firebot_host=%firebot_host%
  echo firebot_home=%firebot_home%
  exit /b 0
)

call :getfile FDS_HASH
call :getfile SMV_HASH
call :getfile FDS_REVISION
call :getfile SMV_REVISION
goto eof


::-----------------------------------------------------------------------
:getfile
::-----------------------------------------------------------------------
set file=%1
if NOT exist "%HASHDIR%\%file%" goto getfile_if
  copy "%HASHDIR%\%file%" output\%file% > Nul
  exit /b 0
:getfile_if
pscp  -P 22 %firebot_host%:%firebot_home%/.firebot/apps/%file%     output\%file%     > Nul
if exist output\%file% exit /b 0
set error=1
echo ***Error: unable to download %file% from %firebot_host%:%firebot_home%/.firebot/apps/%file%
exit /b 1

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
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
   exit /b 1
 )
if not (%1)==() goto getopts
exit /b 0

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
exit /b 0

:eof

if "%error%" == "1" exit /b 1
exit /b 0
