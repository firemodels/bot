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
set allrepos=bot cfast cor exp fds fig out radcal smv cad
set webrepos=webpages wikis
set BRANCH=master
set ahead=0

set wc=%repo%\bot\Scripts\bin\wc
set grep=%repo%\bot\Scripts\bin\grep
set gawk=%repo%\bot\Scripts\bin\gawk

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

for %%x in ( %allrepos% ) do ( call :update_repo %%x )

for %%x in ( %webrepos% ) do ( call :update_repo2 %%x )

cd %CURDIR%

goto eof

:update_repo
  set reponame=%1
  echo.
  set repodir=%repo%\%reponame%
  echo ------------------ %reponame% -----------------------------------------
  if not exist %repodir% (
     echo %repo% does not exist, not updating
     exit /b
  )   
  cd %repodir%
  git rev-parse --abbrev-ref HEAD | head -1 > %CURDIR%\gitbranch.out
  set /p CURRENT_BRANCH=<%CURDIR%\gitbranch.out
  if NOT "%CURRENT_BRANCH%" == "%BRANCH%" (
     echo in repo %reponame% expecting branch %BRANCH%, found branch %CURRENT_BRANCH%
     echo update skipped
     exit /b
  )
  echo *** updating from origin
  echo    branch: %branch%
  echo    dir: %repo%\%reponame%
  git fetch origin
  git merge origin/%BRANCH%
  git remote -v | %gawk% "{print $1}" | %grep% firemodels | %wc%  -l > %CURDIR%\have_central.out
  set /p have_central=<%CURDIR%\have_central.out

  if "%have_central%" == "0" goto skip1
     echo.
     echo *** updating from firemodels
     echo    branch: %branch%
     echo    dir: %repo%\%reponame%
     git fetch firemodels
     git merge firemodels/%BRANCH%
     git status -uno | %grep% ahead | %wc% -l > %CURDIR%\ahead.out
     if exist %CURDIR%\ahead.out (
        set /p ahead=<%CURDIR%\ahead.out
        if %ahead% GTR 0 (
           echo pushing %ahead% changes to origin
           git push origin %BRANCH%
        )
     )
  )
  :skip1
  exit /b

:update_repo2
  set reponame=%1
  echo.
  set repodir=%repo%\%reponame%
  if not exist %repodir% (
     exit /b
  )   
  echo ------------------ %reponame% -----------------------------------------
  cd %repodir%
  git rev-parse --abbrev-ref HEAD | head -1 > %CURDIR%\gitbranch.out
  set /p BRANCH=<%CURDIR%\gitbranch.out
  
  echo *** updating from origin
  echo    branch: %branch%
  echo    dir: %repo%\%reponame%
  git fetch origin
  git merge origin/%BRANCH%
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
echo Update the repos %allrepos% if they exist
echo.
echo Options:
echo -h - display this message
exit /b

:eof
if exist %CURDIR%\gitbranch.out (
  erase %CURDIR%\gitbranch.out
)
if exist %CURDIR%\have_central.out (
  erase %CURDIR%\have_central.out
)
if exist %CURDIR%\ahead.out (
  erase %CURDIR%\ahead.out
)
