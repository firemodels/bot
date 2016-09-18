@echo off
setlocal

set CURDIR=%CD%

if not exist ..\.gitbot goto skip1
   cd ..\..
   set FMROOT=%CD%
   cd %CURDIR%
   goto endif1
:skip1
   echo ***error: update_repos.bat must be run in the bot\Scripts directory
   exit /b
:endif1

set wc=%FMROOT%\bot\Scripts\wc
set grep=%FMROOT%\bot\Scripts\grep
set gawk=%FMROOT%\bot\Scripts\gawk
set head=%FMROOT%\bot\Scripts\head
set disable_push=0

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

cd %FMROOT\bot
set allrepos=bot cfast cor exp fds out radcal smv
set BRANCH=master
set PUSH=0

for %%x in ( %allrepos% ) do ( call :show_remotes %%x )

cd %CURDIR%

goto eof

:show_remotes
  set repo=%1
  echo.
  set repodir=%FMROOT%\%repo%
  echo -------------------%repo%-------------------------------------
  if not exist %repodir% (
     exit /b
  )   
  cd %repodir%
  git remote -v
  git remote -v | %grep% firemodels | %grep% push | %gawk% "{print $2}" | %grep% github | %grep% firemodels | %wc% -l > %CURDIR%\nbadpush.out
  set /p nbadpush=<%CURDIR%\nbadpush.out
  if %nbadpush% GTR 0 (
    if %disable_push% EQU 1 (
      git remote set-url --push firemodels DISABLE
    ) else (
      echo push access to firemodels is enabled
      echo to disable, rerun show_remotes with the -d option
    )
    
  )
  erase %CURDIR%\nbadpush.out
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
 if /I "%1" EQU "-d" (
   set disable_push=1   
   set valid=1
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
echo Show remotes for repos %allrepos% if they exist
echo.
echo Options:
echo -d - disable push access to firemodels for %allrepos%
echo -h - display this message
exit /b

:eof
