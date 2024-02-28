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
  Title Build Smokeview User Guide

  cd %git_root%\smv\Manuals\SMV_User_Guide\
  call make_guide
  goto eof
)
if "%guide%" == "Verification" (
  Title Build Smokeview Verification Guide

  cd %git_root%\smv\Manuals\SMV_Verification_Guide\
  call make_guide
  goto eof
)
if "%guide%" == "Validation" (
  echo Smokeview does not have a Validation guide
  goto eof
)
if "%guide%" == "Technical" (
  Title Build Smokeview Technical Reference Guide

  cd %git_root%\smv\Manuals\SMV_Technical_Reference_Guide\
  call make_guide
  goto eof
)
goto eof
:skip_fds
if "%guide%" == "User" (
  Title Build FDS User Guide

  cd %git_root%\fds\Manuals\FDS_User_Guide\
  call make_guide
  goto eof
)
if "%guide%" == "Validation" (
  Title Build FDS Validation Guide
  cd %git_root%\fds\Manuals\FDS_Validation_Guide\
  call make_guide
  goto eof
)
if "%guide%" == "Verification" (
  Title Build FDS Verification Guide

  cd %git_root%\fds\Manuals\FDS_Verification_Guide\
  call make_guide
  goto eof
)
if "%guide%" == "Technical" (
  Title Build FDS Technical Reference Guide

  cd %git_root%\fds\Manuals\FDS_Technical_Reference_Guide\
  call make_guide
  goto eof
)

:eof
pause
