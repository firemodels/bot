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
set allrepos=bot cad cfast cor exp fds fig out radcal smv test_bundles
set webrepos=webpages wikis smvwiki
set BRANCH=master
set "pushrepos="
set "updaterepos=%allrepos%"

set wc=%repo%\bot\Scripts\bin\wc
set grep=%repo%\bot\Scripts\bin\grep
set gawk=%repo%\bot\Scripts\bin\gawk
set setbranchmaster=
set updatewebwiki=0
set status_only=0

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

if %updatewebwiki% == 1 goto endif1
for %%x in ( %updaterepos% ) do ( call :update_repo %%x )
:endif1

if %updatewebwiki% == 0 goto endif2
for %%x in ( %webrepos% ) do ( call :update_repo2 %%x )
:endif2

if %status_only% == 1 (
  echo status complete
) else (
  echo update complete
)
for %%x in (%pushrepos%) do (
  echo.
  echo WARNING: A git push is required to sync %%x origin/%BRANCH% with firemodels/%BRANCH%.
  echo git -C "%repo%\%%x" push origin %BRANCH%
)

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
  if %status_only% == 1 (
    git -C "%repodir%" status -uno
    exit /b
  )
  cd %repodir%
  if "x%setbranchmaster%" == "x" goto skip_setbranch
    git checkout master
:skip_setbranch
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
  git remote update || exit /b 1
  git merge "origin/%BRANCH%" || exit /b 1
  git remote -v | %gawk% "{print $1}" | %grep% firemodels | %wc%  -l > %CURDIR%\have_central.out
  set /p have_central=<%CURDIR%\have_central.out

  if "%have_central%" == "0" goto skip1
     echo.
     echo *** updating from firemodels
     echo    branch: %branch%
     echo    dir: %repo%\%reponame%
     git merge firemodels/%BRANCH% || exit /b 1
     git merge-base --is-ancestor HEAD "origin/%BRANCH%"
     if errorlevel 1 if not errorlevel 2 (
       echo.
       echo WARNING: A git push is required to sync %reponame% origin/%BRANCH% with firemodels/%BRANCH%.
       echo git -C "%repodir%" push origin %BRANCH%
       set "pushrepos=%pushrepos% %reponame%"
     )
  :skip1

  if "%repo%" == "exp" (
     git submodule foreach git remote update
     git submodule foreach git merge origin/master
  )

  exit /b

:update_repo2
  set reponame=%1
  echo.
  set repodir=%repo%\%reponame%
  if not exist %repodir% (
     exit /b
  )
  echo ------------------ %reponame% -----------------------------------------
  if %status_only% == 1 (
    git -C "%repodir%" status -uno
    exit /b
  )
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
 if /I "%1" EQU "-b" (
   set valid=1
   set updaterepos=bot
 )
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "-m" (
   set valid=1
   set setbranchmaster=1
 )
 if /I "%1" EQU "-s" (
   set valid=1
   set status_only=1
 )
 if /I "%1" EQU "-w" (
   set valid=1
   set updatewebwiki=1
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
echo -b - update only bot repo
echo -h - display this message
echo -m - checkout the master branch before updating a repo
echo -s - run git status -uno without updating
echo -w - update web and wik repos
exit /b

:eof
if exist %CURDIR%\gitbranch.out (
  erase %CURDIR%\gitbranch.out
)
if exist %CURDIR%\have_central.out (
  erase %CURDIR%\have_central.out
)
