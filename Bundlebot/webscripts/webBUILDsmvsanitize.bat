@echo off
set platform=%1
set option=%2 

:: batch file to build test or release smokeview on Windows, Linux or OSX platforms

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
echo.
echo  Building test Smokeview for %platform%
Title Building test Smokeview for %platform%

%git_drive%

if "%platform%" == "Windows" (
  cd %git_root%\smv\Build\smokeview\clang_win
  call make_smokeview_db
  if exist smokeview_win.exe copy smokeview_win.exe ..\intel_win
  if not exist smokeview_win.exe echo smokeview_win.exe failed to build
  goto eof
)

:: ----------- linux -----------------

if "%platform%" == "Linux" (
::  plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command.sh smv/Build/smokeview/intel_linux make_smokeview_db.sh -t -s
  echo sanitize option not available for Linux
  goto eof
)

:: ----------- osx -----------------

if "%platform%" == "OSX" (
  echo sanitize option not available for OSX
  goto eof
)

:eof
echo.
echo compilation complete
pause
