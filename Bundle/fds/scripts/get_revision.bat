@echo off

set repo_type=fds
::set firebot_home=~firebot
set firebot_home=/home2/smokevis2/firebot
set firebot_host=blaze.el.nist.gov
set to_dir=/tmp
set SHOWPARMS=0
call :getopts %*

if "%SHOWPARMS%" == "1" (
  echo firebot_host=%firebot_host%
  echo firebot_home=%firebot_home%
  echo to_dir=%to_dir%
  echo repo_type=%repo_type%
  exit /b
)

call :CP .firebot/apps/FDS_REVISION FDS_REVISION
type FDS_REVISION
goto eof

::-----------------------------------------------------------------------
:CP
::-----------------------------------------------------------------------

  set FROMFILE=%1
  set TOFILE=%2
  set COPY=0
  pscp  %firebot_host%:%firebot_home%/%FROMFILE% %TOFILE% > Nul
  exit /b

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------

:getopts
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-e" (
   shift
   set error_log=%1
   set valid=1
 )
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
 if /I "%1" EQU "-r" (
   shift
   set repo_type=%1
   set valid=1
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
echo -e - error log
echo -g - host where firebot was run
echo -G - home directory where firebot was run
echo -h - display this message
echo -r - repo type fds or  smv
echo -v - show parameters used to build bundle (the bundle is not generated)
exit /b

:eof

exit /b
