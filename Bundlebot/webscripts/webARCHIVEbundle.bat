@echo off
setlocal EnableDelayedExpansion

set stopscript=0
call :getopts %*
if %stopscript% == 1 (
  exit /b
)
if NOT "%valid%" == "1" (
  call :usage
  exit /b
)

set platform=%1
set upload_dir=%userprofile%\.bundle\bundles

:: batch file to generate Windows, Linux or OSX FDS-SMV bundles

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
set env_defined=1

set version=%smv_revision%

echo.
echo   Archiving FDS-Smokeview bundle for %platform%
Title  Archiving FDS-Smokeview bundle for %platform%

%git_drive%

if "%platform%" == "windows" (
  goto eof
)
if "%platform%" == "linux" (
  plink %plink_options% %linux_logon% %linux_git_root%/bot/Bundlebot/smv/scripts/archive_bundle.sh %version%_lnx
  goto eof
)
if "%platform%" == "osx" (
  plink %plink_options% %osx_logon% %linux_git_root%/bot/Bundlebot/smv/scripts/archive_bundle.sh %version%_osx
  goto eof
)

goto eof

:getopts
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-help" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "windows" (
   set valid=1
 )
 if /I "%1" EQU "linux" (
   set valid=1
 )
 if /I "%1" EQU "osx" (
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

:usage  
echo webBUNDLEfdssmv [options] platform
echo. 
echo -help           - display this message
echo platform        - platform can be windows, linux or osx
exit /b

:eof
echo.
echo archive complete
pause
