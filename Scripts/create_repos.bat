@echo off
setlocal
set CURDIR=%CD%

:: 1. run in local directory (if bot/Scripts )
:: 2. run using %FIREMODELS% variable (if not in bot/Scripts
:: 3. run using directory defined by -r option

if not exist ..\.gitbot goto skip1
   cd ..\..
   set FMROOT=%CD%
   cd %CURDIR%
:skip1

if "%FMROOT%" == "" (
   set FMROOT=%FIREMODELS%
)

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

if "%FMROOT%" == "" (
   echo ***Error: repo directory not defined.  
   echo           Rerun create_repos script in the bot\Scripts directory,
   echo           use the -r option or define the FIREMODELS
   echo           environment variable to define a repo location
   exit /b
)

if NOT exist %FMROOT% (
   echo ***Error: The directory %FMROOT% does not exist
   exit /b
)

if NOT exist %FMROOT%\bot (
   echo ***Error: The directory %FMROOT%\bot does not exist
   echo           You need to clone the bot directory under %FMROOT% from github
   exit /b
)
cd %FMROOT%\bot

git remote -v | grep origin | head -1 | gawk  "{print $2}" | gawk -F ":" "{print $1}">%CURDIR%\githeader.out
set /p GITHEADER=<%CURDIR%\githeader.out

if "%GITHEADER%" == "git@github.com" (
   set GITHEADER=%GITHEADER%:
   git remote -v | grep origin | head -1 | gawk -F ":" "{print $2}" | gawk -F\\/ "{print $1}" > %CURDIR%\gituser.out
   set /p GITUSER=<%CURDIR%\gituser.out
) else (
   set GITHEADER=https://github.com/
   git remote -v | grep origin | head -1 | gawk -F "." "{print $2}" | gawk -F\\/ "{print $2}" > %CURDIR%\gituser.out
   set /p GITUSER=<%CURDIR%\gituser.out
)

set fdsrepos=exp fds out smv
set smvrepos=cfast fds smv
set cfastrepos=cfast exp smv
set allrepos= cfast cor exp fds out radcal smv
set repos=%fdsrepos%

erase %CURDIR%\gituser.out
erase %CURDIR%\githeader.out

echo You are about to clone the repos: %repos%
echo from %GITHEADER%%GITUSER%
echo.
echo Press any key to continue, CTRL c to abort or type 
echo create_repos -h for other options
pause >Nul

for %%x in ( %repos% ) do ( call :create_repo %%x )
echo repo creation completed
cd %CURDIR%

goto eof

:create_repo
  set repo=%1
  set repodir=%FMROOT%\%repo%
  echo -----------------------------------------------------------

:: check if repo is at github
  call :at_github %repo%
  
  if %git_not_found% GTR 0 (
     echo ***Error: The repo %GITHEADER%%GITUSER%/%repo%.git was not found.
     exit /b
  )

:: check if repo has been cloned locally
  if exist %repodir% (
     echo Skipping %repo%, the repo directory %repodir% already exists
     exit /b
  )

  cd %FMROOT%
  if "%repo%" == "exp" (
     git clone --recursive %GITHEADER%%GITUSER%/%repo%.git
  )  else (
     git clone %GITHEADER%%GITUSER%/%repo%.git
  )
  if "%GITUSER%" == "firemodels"  (
     exit /b
  )
  echo setting up remote tracking
  cd %repodir%
  git remote add firemodels %GITHEADER%firemodels/%repo%.git
  git remote update
  exit /b

:at_github
  set repo=%1
  git ls-remote %GITHEADER%%GITUSER%/%repo%.git 1> %CURDIR%\gitstatus.out 2>&1
  type %CURDIR%\gitstatus.out | grep ERROR | wc -l > %CURDIR%\gitstatus2.out
  set /p git_not_found=<%CURDIR%\gitstatus2.out
  exit /b

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
 if /I "%1" EQU "-r" (
   set valid=1
   set FMROOT=%2
   shift
 )
 if /I "%1" EQU "-s" (
   set valid=1
   set repos=%smvrepos%
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
echo Setup repos ( default: %repos% ) 
echo used by cfast, fds and/or smokeview
echo.
echo Options:
echo -a - setup all repos: %allrepos%
echo -c - setup repos used by cfastbot: %cfastrepos%
echo -f - setup repos used by firebot: %fdsrepos%
echo -r repodir - directory containing firemodels repos
echo -s - setup repos used by smokebot: %smvrepos%
echo -h - display this message%
exit /b

:eof
erase %CURDIR%\gitstatus.out
erase %CURDIR%\gitstatus2.out
