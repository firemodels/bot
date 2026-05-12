@echo off
set app=%1
setlocal EnableDelayedExpansion

::  batch to copy SMV_Summary directory to local repo

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
cd %git_root%\bot\Scripts\files
set FILESDIR=%CD%
set SMVREPO=%git_root%\smv

cd ..

if "%app%" == "FDS" goto skip_smv

call :DOWNLOADFILE SMOKEVIEW_TEST SMV_Summary.tar.gz
call :COPYFILES %FILESDIR% SMV_Summary.tar.gz
cd %FILESDIR%\SMV_Summary
goto end_fds
:skip_smv
call :DOWNLOADFILE FDS_TEST FDS_Summary.tar
call :COPYFILES %FILESDIR% FDS_Summary.tar
cd %FILESDIR%\FDS_Summary

:end_fds

index.html
goto eof


::-----------------------------------------------------------------------
:DOWNLOADFILE
::-----------------------------------------------------------------------
  set TAG=%1
  set FILE=%2
  echo.
  echo downloading %FILE% to %FILESDIR%
  gh release download %TAG% -p %FILE% -D %FILESDIR% --clobber -R github.com/%GH_OWNER%/%GH_REPO%
  exit /b

::-----------------------------------------------------------------------
:COPYFILES
::-----------------------------------------------------------------------
  set TODIR=%1
  set FILE=%2
  if NOT EXIST %TODIR% goto copy_else1
    echo untarring %FILE% to %TODIR%
    cd %TODIR%
    if NOT EXIST %FILESDIR%\%FILE% goto copy_else2
      tar xf %FILESDIR%\%FILE% 
      git checkout .gitignore 2> Nul
      goto copy_endif1
    :copy_else2
      echo "***error: %FILESDIR%\%FILE% does not exist"
      goto copy_endif1
    copy_endif2
  :copy_else1
    echo ***error: %TODIR% does not exist
  :copy_endif1
  exit /b

:eof
echo.
echo copy complete
pause
