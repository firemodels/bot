@echo off
setlocal

set repo_root=FireModels_fork
set CURDIR=%CD%
set user=%USERNAME%
set repo=test_bundles

:: setup environment variables (defining where repository resides etc) 

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
pause>NUL
goto:eof

:endif_envexist

call %envfile%
%svn_drive%
echo.

call :getopts %*
if %stopscript% == 1 exit /b

set scriptdir=%linux_svn_root%/bot/Scripts

echo Repo root: %repo_root%
echo      Repo: %repo%
echo      user: %user%
echo        PC: %COMPUTERNAME%
echo     Linux: %linux_logon%
echo       OSX: %osx_logon%

cd %userprofile%\%repo_root%\%repo%
echo.
echo %COMPUTERNAME%:
gh repo set-default %user%/%repo% 
gh repo set-default --view 

echo.
echo %linux_logon%:
echo gh repo set-default %user%/%repo% 
plink %plink_options% %linux_logon% %scriptdir%/set_gh_defaults.sh %repo_root% %repo% %user%

echo.
echo.
echo %osx_logon%:
echo gh repo set-default %user%/%repo% 
plink %plink_options% %osx_logon% %scriptdir%/set_gh_defaults.sh %repo_root% %repo% %user%
goto eof

::---------------------------------------
:usage
::---------------------------------------
echo set default repository used by gh
echo to firemodels (-f) or %username% (-u)
echo.
echo Options:"
echo -f           - set default repository to firemodels  
echo -h           - display this message
echo -r repo_root - set repo_root (default: %repo_root%)
echo -R repo      - set repo (default: %repo%)
echo -u           - set default reposity to %username%  (default)
exit /b

::---------------------------------------
:getopts
::---------------------------------------
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "-f" (
   set valid=1
   set user=firemodels
 )
 if /I "%1" EQU "-u" (
   set user=%username%
   set valid=1
 )
 if "%1" EQU "-r" (
   set repo_root=%2
   shift
   set valid=1
 )
 if "%1" EQU "-R" (
   set repo=%2
   shift
   set valid=1
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

:eof