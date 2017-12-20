@echo off
setlocal

set CURDIR=%CD%

if not exist ..\.gitbot goto skip1
   cd ..\..
   set FMROOT=%CD%
   cd %CURDIR%
   goto endif1
:skip1
   echo ***error: This script must be run in the bot\Scripts directory
   exit /b
:endif1

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

cd %FMROOT%\bot
set allrepos=bot cfast cor exp fds out radcal smv
set BRANCH=master

for %%x in ( %allrepos% ) do ( call :show_status %%x )

cd %CURDIR%

goto eof

:show_status
  set repo=%1
  echo.
  set repodir=%FMROOT%\%repo%
  echo -------------------%repo%-------------------------------------
  if not exist %repodir% (
     exit /b
  )   
  cd %repodir%
  git describe --dirty
  exit /b

goto eof

:getopts
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
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

:usage
echo Show status for repos %allrepos% if they exist
echo.
echo Options:
echo -h - display this message
exit /b

:eof
