@echo off
:: usage: 
::  run_smokebot -cfastrepo name -fdsrepo name -altemail -email address -nomatlab -noupdate
::  (all command arguments are optional)

set altemail=0
set clean=0
set update=0
set stopscript=0
set force=0

if NOT exist .smv_git (
   echo ***error: smokebot not running in the bot\Smokebot directory
   echo           smokebot aborted
   exit /b
)

set emailto=
if not x%EMAILGIT% == x (
  set emailto=%EMAILGIT%
)

:: parse command line arguments

set stopscript=0
call :getopts %*
if %stopscript% == 1 (
  exit /b
)

:: normalize directory paths

call :normalise %CD%
set curdir=%temparg%

set repo=%RUNDIR%\..\..
call :normalise %repo%
set repo=%temparg%

set cfastrepo=%repo%\cfast
call :normalise %cfastrepo% 
set cfastrepo=%temparg%

set fdsrepo=%repo%\fds
call :normalise %fdsrepo%
set fdsrepo=%temparg%

set smvrepo=%repo%\smv
call :normalise %smvrepo%
set smvrepo=%temparg%

call :normalise %fdsrepo%\bot\Smokebot
set smvbotdir=%temparg%

set running=%curdir%\smokebot.running

if "%force%" EQU "1" goto skip_runtest
if exist %running% goto skip_running
:skip_runtest

:: get latest smokebot

if %update% == 0 goto no_update
   echo getting latest smokebot
   cd %smvbotdir%
   git fetch origin
   git merge origin/master 1> Nul 2>&1
   cd %curdir%
:no_update

:: run smokebot

  echo 1 > %running%
  call smokebot.bat %repo% %clean% %update% %altemail% %emailto%
  if exist %running% erase %running%
  goto end_running
:skip_running
  echo ***Error: smokebot is currently running.
  echo If this is not the case, erase the file:
  echo %running%
  echo or use the -force option
:end_running

goto eof

:getopts
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-altemail" (
   set valid=1
   set altemail=1
 )
 if /I "%1" EQU "-bot" (
   set valid=1
   set clean=1
   set update=1
 )
 if /I "%1" EQU "-repo" (
   set repo=%2
   set valid=1
   shift
 )
 if /I "%1" EQU "-clean" (
   set valid=1
   set clean=1
 )
 if /I "%1" EQU "-email" (
   set emailto=%2
   set valid=1
   shift
 )
 if /I "%1" EQU "-force" (
   set valid=1
   set force=1
 )
 if /I "%1" EQU "-help" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "-update" (
   set valid=1
   set update=1
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
echo run_smokebot [options]
echo. 
echo -help           - display this message
echo -repo name - specify the directory containing the smv and fds repos
echo       (default: %repo%) 
echo -altemail       - use an alternate email server
echo -email address  - override "to" email addresses specified in repo 
if "%emailto%" NEQ "" (
echo       (default: %emailto%^)
)
echo -bot            - clean and update repository
echo -clean          - clean repository
echo -update         - update repository
exit /b

:normalise
set temparg=%~f1
exit /b

:eof

