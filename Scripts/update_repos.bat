@echo off
setlocal

set CURDIR=%CD%

if not exist ..\.gitbot goto skip1
   cd ..\..
   set repo=%CD%
   cd %CURDIR%
   goto endif1
:skip1
   echo ***error: update_repos.bat must be run in the bot\Scripts directory
   exit /b
:endif1

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

cd %repo%\bot
set allrepos=bot cfast cor exp fds out radcal smv
set webrepos=webpages wikis
set BRANCH=master
set PUSH=0

set wc=%repo%\bot\Scripts\wc
set grep=%repo%\bot\Scripts\grep
set gawk=%repo%\bot\Scripts\gawk

for %%x in ( %allrepos% ) do ( call :update_repo %%x )

for %%x in ( %webrepos% ) do ( call :update_repo2 %%x )

cd %CURDIR%

goto eof

:update_repo
  set reponame=%1
  echo.
  set repodir=%repo%\%reponame%
  echo -----------------------------------------------------------
  if not exist %repodir% (
     echo %repo% does not exist, not updating
     exit /b
  )   
  cd %repodir%
  git rev-parse --abbrev-ref HEAD | head -1> %CURDIR%\gitbranch.out
  set /p CURRENT_BRANCH=<%CURDIR%\gitbranch.out
  if NOT "%CURRENT_BRANCH%" == "%BRANCH%" (
     echo %BRANCH% branch not checkout out in %repo%
     echo update skipped
     exit /b
  )
  echo repo: %reponame% - updating from origin
  echo   branch: %branch%
  echo      dir: %repo%\%reponame%
  git fetch origin
  git merge origin/%BRANCH%
  git remote -v | %gawk% "{print $1}" | %grep% firemodels | %wc%  -l> %CURDIR%\have_central.out
  set /p have_central=<%CURDIR%\have_central.out

  if %have_central% GTR 0 (
     echo.
     echo repo: %reponame% - updating from firemodels
     echo   branch: %branch%
     echo      dir: %repo%\%reponame%
     git fetch firemodels
     git merge firemodels/%BRANCH%
     if "%PUSH%" == "1" (
        echo pushing changes in %repo% to origin"
        git push origin %BRANCH%
     )
  )
  exit /b

:update_repo2
  set reponame=%1
  echo.
  set repodir=%repo%\%reponame%
  if not exist %repodir% (
     exit /b
  )   
  echo -----------------------------------------------------------
  cd %repodir%
  git rev-parse --abbrev-ref HEAD | head -1> %CURDIR%\gitbranch.out
  set /p BRANCH=<%CURDIR%\gitbranch.out
  
  echo repo: %reponame% - updating from origin
  echo   branch: %branch%
  echo      dir: %repo%\%reponame%
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
 if /I "%1" EQU "-p" (
   set valid=1
   set PUSH=1
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
echo -p - push updates to remote origin
exit /b

:eof
erase %CURDIR%\gitbranch.out
erase %CURDIR%\have_central.out
