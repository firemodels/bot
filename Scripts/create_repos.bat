@echo off
git remote -v | grep origin | head -1 | gawk -F ":" "{print $2}" | gawk -F\\/ "{print $1}" > gituser.out
set /p GITUSER=<gituser.out

set fdsrepos=exp fds out smv
set smvrepos=cfast fds smv
set cfastrepos=cfast exp smv
set allrepos=cfast cor exp fds out radcal smv
set repos=%fdsrepos%

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

echo You are about to clone the repos: %repos%
echo from git@github.com:%GITUSER%
echo.
echo Press any key to continue, CTRL c to abort or type 
echo create_repos -h for other options
pause >Nul


set CURDIR=%CD%
cd ..\..
set FIREMODELS=%CD%
for %%x in ( %repos% ) do call :create_repo %%x
         )
echo repo creation completed
cd %CURDIR%

goto eof

:create_repo
  set repo=%1
  set repodir=%FIREMODELS%\%repo%
  echo "-----------------------------------------------------------"
  if exist %repodir% (
     echo Skipping %repo%.  The directory %repodir% already exists.
     exit /b
  )
  cd %FIREMODELS%
  if "%repo%" == "exp" (
     git clone --recursive git@github.com:%GITUSER%/%repo%.git
  )  else (
     git clone git@github.com:%GITUSER%/%repo%.git
  )
  if "%GITUSER%" == "firemodels"  (
     exit /b
  )
  echo setting up remote tracking
  cd %repodir%
  git remote add firemodels git@github.com:firemodels/%repo%.git
  git remote update
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
echo -s - setup repos used by smokebot: %smvrepos%
echo -h - display this message%
exit /b

:eof