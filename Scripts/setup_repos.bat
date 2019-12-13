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
   exit /b 1
:endif1

set fdsrepos=exp fds fig out smv
set fdssmvrepos=fds smv
set smvrepos=cfast fds fig smv
set cfastrepos=cfast exp fig smv 
set allrepos= cad cfast cor exp fds fig out radcal smv
set wikiwebrepos= fds.wiki fds-smv
set repos=%fdsrepos%
set WIKIWEB=0
set erase_repos=0
set pause_script=1

call :getopts %*
if %stopscript% == 1 (
  exit /b 0
)

cd %FMROOT%\bot

set wc=%FMROOT%\bot\Scripts\bin\wc
set grep=%FMROOT%\bot\Scripts\bin\grep
set gawk=%FMROOT%\bot\Scripts\bin\gawk
set head=%FMROOT%\bot\Scripts\bin\head

git remote -v | %grep% origin | %head% -1 | %gawk%  "{print $2}" | %gawk% -F ":" "{print $1}">%CURDIR%\githeader.out
set /p GITHEADER=<%CURDIR%\githeader.out

if "%GITHEADER%" == "git@github.com" (
   set GITHEADER=%GITHEADER%:
   git remote -v | %grep% origin | %head% -1 | %gawk% -F ":" "{print $2}" | %gawk% -F\\/ "{print $1}" > %CURDIR%\gituser.out
   set /p GITUSER=<%CURDIR%\gituser.out
) else (
   set GITHEADER=https://github.com/
   git remote -v | %grep% origin | %head% -1 | %gawk% -F "." "{print $2}" | %gawk% -F\\/ "{print $2}" > %CURDIR%\gituser.out
   set /p GITUSER=<%CURDIR%\gituser.out
)

if exist %CURDIR%\gituser.out erase %CURDIR%\gituser.out
if exist %CURDIR%\githeader.out erase %CURDIR%\githeader.out

echo You are about to clone the repos: %repos%
if "%WIKIWEB%" == "1" (
   echo from git@github.com:firemodels into the directory: %FMROOT%
) else (
   echo from %GITHEADER%%GITUSER% into the directory: %FMROOT%
)
if "%pause_script%" == "1" (
  echo.
  echo Press any key to continue, CTRL c to abort or type 
  echo setup_repos -h for other options
  pause >Nul
)

for %%x in ( %repos% ) do ( call :create_repo %%x )

cd %CURDIR%

goto eof

::-----------------------------------------------------------------------
:create_repo
::-----------------------------------------------------------------------
  set repo=%1
  set repo_out=%repo%
  
  echo -----------------------------------------------------------

  set WIKIWEB=

  if "%repo%" == "fds.wiki" (
     set repo_out=wikis
     set WIKIWEB=1
  )
  if "%repo%" == "fds-smv" (
     set repo_out=webpages
     set WIKIWEB=1
  )

  set repo_dir=%FMROOT%\%repo_out%
  if "%erase_repos%" == "1" (
    if exist %repo_dir% echo erasing %repo_dir%
    if exist %repo_dir% rmdir /S /Q %repo_dir%
  )
  
:: check if repo has been cloned locally
  if exist %repo_dir% (
     echo Skipping %repo%, the repo directory:
     echo %repo_dir%
     echo already exists
     exit /b 0
  )

  if "%WIKIWEB%" == "1" (
     cd %FMROOT%
     git clone %GITHEADER%firemodels/%repo%.git %repo_out%
     exit /b 0
  )
  
:: check if repo is at github
  call :at_github %repo%
  
  if %git_not_found% GTR 0 (
     echo ***Error: The repo %GITHEADER%%GITUSER%/%repo%.git was not found.
     exit /b 1
  )

  cd %FMROOT%
  if "%repo%" == "exp" (
     git clone --recursive %GITHEADER%%GITUSER%/%repo%.git %repo_out%
  )  else (
     git clone %GITHEADER%%GITUSER%/%repo%.git %repo_out%
  )
  if "%GITUSER%" == "firemodels"  (
     exit /b 0
  )
  echo setting up remote tracking
  cd %repo_dir%
  git remote add firemodels %GITHEADER%firemodels/%repo%.git
  git remote set-url --push firemodels DISABLE
  git remote update
  exit /b 0

::-----------------------------------------------------------------------
:at_github
::-----------------------------------------------------------------------
  set repo=%1
  git ls-remote %GITHEADER%%GITUSER%/%repo%.git 1> %CURDIR%\gitstatus.out 2>&1
  type %CURDIR%\gitstatus.out | %grep% ERROR | %wc% -l > %CURDIR%\gitstatus2.out
  set /p git_not_found=<%CURDIR%\gitstatus2.out
  exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "-a" (
   set valid=1
   set repos=%allrepos%
 )
 if /I "%1" EQU "-c" (
   set valid=1
   set repos=%cfastrepos%
 )
 if /I "%1" EQU "-f" (
   set valid=1
   set repos=%fdsrepos%
 )
 if /I "%1" EQU "-n" (
   set valid=1
   set pause_script=0
 )
 if /I "%1" EQU "-s" (
   set valid=1
   set repos=%smvrepos%
 )
 if /I "%1" EQU "-w" (
   set valid=1
   set repos=%wikiwebrepos%
 )
 if /I "%1" EQU "-T" (
   set valid=1
   set erase_repos=1
   set repos=%fdssmvrepos%
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
echo Setup repos ( default: %repos% ) 
echo used by cfast, fds and/or smokeview
echo.
echo Options:
echo -a - setup all repos: %allrepos%
echo -c - setup repos used by cfastbot: %cfastrepos%
echo -f - setup repos used by firebot: %fdsrepos%
echo -h - display this message%
echo -s - setup repos used by smokebot: %smvrepos%
echo -T - setup only fds and smv repos - erase repos first
echo -w - setup wiki and webpage repos cloned from firemodels
exit /b 0

::-----------------------------------------------------------------------
:eof
::-----------------------------------------------------------------------
if exist %CURDIR%\gitstatus.out erase %CURDIR%\gitstatus.out
if exist %CURDIR%\gitstatus.out erase %CURDIR%\gitstatus2.out

exit /b 0


