@echo off
:: platform is windows, linux or osx
set platform=%1
set scan_bundle=%2

:: build type is test or release
set buildtype=%2

set nopause=nopause

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

%git_drive%

set type=test
set version=%smv_revision%

echo.
echo  Bundling %type% Smokeview for %platform%
Title Bundling %type% Smokeview for %platform%

:: windows

if "%platform%" == "Windows" (
  cd %git_root%\bot\Bundlebot\release
  call make_smv_bundle %version%
  goto eof
)

cd %git_root%\smv\scripts

set scriptdir=%linux_git_root%/bot/Bundlebot/nightly
set bundledir=.bundle/bundles
set todir=%userprofile%\.bundle
set bundlesdir=%todir%\bundles

if NOT exist %todir% mkdir     %todir%
if NOT exist %bundlesdir% mkdir %bundlesdir%

:: linux

if "%platform%" == "Linux" (

  echo.
  echo --- Making a Linux Smokeview installer ---
  echo.
  plink %plink_options% %linux_logon% %scriptdir%/assemble_smvbundle.sh %buildtype% %version% %linux_git_root%
  goto eof
)

:: osx

if "%platform%" == "OSX" (
  echo.
  echo --- Making a OSX Smokeview installer ---
  echo.
  plink %plink_options% %osx_logon% %scriptdir%/assemble_smvbundle.sh %buildtype% %version% %linux_git_root%
  goto eof
)

:eof
if "x%nopause%" == "xnopause" goto eof2
echo.
echo Bundle build complete
pause
:eof2
