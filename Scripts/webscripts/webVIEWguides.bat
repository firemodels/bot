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

if "%app%" == "FDS" goto skip_fds
if "%guide%" == "User" (
  Title View Smokeview User Guide

  cd %git_root%\smv\Manuals\SMV_User_Guide\
  start sumatrapdf SMV_User_Guide.pdf
  goto eof
)
if "%guide%" == "Verification" (
  Title View Smokeview Verification Guide

  cd %git_root%\smv\Manuals\SMV_Verification_Guide\
  start sumatrapdf SMV_Verification_Guide.pdf
  goto eof
)
if "%guide%" == "Validation" (
  echo Smokeview does not have a Validation guide
  goto eof
)
if "%guide%" == "Technical" (
  Title View Smokeview Technical Reference Guide

  cd %git_root%\smv\Manuals\SMV_Technical_Reference_Guide\
  start sumatrapdf SMV_Technical_Reference_Guide.pdf
  goto eof
)
goto eof
:skip_fds
if "%guide%" == "User" (
  Title View FDS User Guide

  cd %git_root%\fds\Manuals\FDS_User_Guide\
  start sumatrapdf FDS_User_Guide.pdf
  goto eof
)
if "%guide%" == "Validation" (
  Title View FDS Validation Guide
  cd %git_root%\fds\Manuals\FDS_Validation_Guide\
  start sumatrapdf FDS_Validation_Guide.pdf
  goto eof
)
if "%guide%" == "Verification" (
  Title View FDS Verification Guide

  cd %git_root%\fds\Manuals\FDS_Verification_Guide\
  call make_guide
  goto eof
)
if "%guide%" == "Technical" (
  Title View FDS Technical Reference Guide

  cd %git_root%\fds\Manuals\FDS_Technical_Reference_Guide\
  start sumatrapdf FDS_Technical_Reference_Guide.pdf
  goto eof
)

:eof
pause
