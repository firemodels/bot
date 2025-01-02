@echo off
setlocal

set CURDIR=%CD%

if not exist ..\.gitbot goto skip1
   cd ..\..
   set repo=%CD%
   cd %CURDIR%
   goto endif1
:skip1
   echo ***error: This script must be run in the bot\Scripts directory
   exit /b
:endif1

cd %repo%\bot
set allrepos=bot cfast fds smv

for %%x in ( %allrepos% ) do ( call :prune_repo %%x )

echo prune complete

cd %CURDIR%

goto eof

:prune_repo
  set reponame=%1
  echo.
  set repodir=%repo%\%reponame%
  echo ------------------ %reponame% -----------------------------------------
  if not exist %repodir% (
     echo %repo% does not exist, not pruning
     exit /b
  )   
  cd %repodir%
  git remote prune origin
  exit /b
:eof
