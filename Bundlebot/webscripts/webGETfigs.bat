@echo off
setlocal EnableDelayedExpansion
set app=%1
set guide=%2

::  batch to copy smokview/smokebot or fdsfirebot figures to local repo

::  setup environment variables (defining where repository resides etc) 

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

%git_drive%
cd %git_root%\bot\Scripts

if "%app%" == "FDS" goto skip_fds
if "%guide%" == "User" (
  Title Download Smokeview User Guide images
  GetFigures -s -u
  goto eof
)
if "%guide%" == "Verification" (
  Title Download Smokeview Verification Guide images
  GetFigures -s -v
  goto eof
)
if "%guide%" == "Validation" (
  echo Smokeview does not have any Validation Guide images to download
  goto eof
)
if "%guide%" == "Technical" (
  echo Smokeview does not have any Technical Guide images to download
  goto eof
)
goto eof
:skip_fds
if "%guide%" == "User" (
  Title Download FDS user guide images
  GetFigures -f -u
  goto eof
)
if "%guide%" == "Validation" (
  Title Download FDS Validation guide %%d images
  GetFigures -f -V
  goto eof
)
if "%guide%" == "Verification" (
  Title Download FDS Verification guide images
  GetFigures -f -v
  goto eof
)
if "%guide%" == "Technical" (
  Title Download FDS Technical Guide images
  GetFigures -f -t
  goto eof
)

:eof
echo.
echo copy complete
pause
