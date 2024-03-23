@echo off
setlocal EnableDelayedExpansion
set platform=%1

:: batch file used to update Windows, Linux and OSX GIT repos

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

:: location of batch files used to set up Intel compilation environment

call %envfile%

if NOT "%platform%" == "Windows" goto skip_windows
echo.
echo ------------------------------------------------------------------------
%git_drive%

echo Cleaning source and build directories in the Windows repository FireModels_fork
echo Cleaning %git_root%\fds\Source
cd %git_root%\fds\Source
git clean -dxf

echo Cleaning %git_root%\fds\Build
cd %git_root%\fds\Build
git clean -dxf

echo Cleaning %git_root%\smv\Source
cd %git_root%\smv\Source
git clean -dxf

echo Cleaning %git_root%\smv\Build
cd %git_root%\smv\Build
git clean -dxf
:skip_windows

set scriptdir=%linux_git_root%/bot/Bundlebot/fds/scripts/

if NOT "%platform%" == "Linux" goto skip_linux
echo.
echo ------------------------------------------------------------------------
echo Cleaning source and build directories in the Linux repository %linux_git_root%, on %linux_hostname%
plink %plink_options% %linux_logon% %scriptdir%/clean_repo_sourcebuild.sh
:skip_linux

if NOT "%platform%" == "OSX" goto skip_osx
echo.
echo ------------------------------------------------------------------------
echo Cleaning source and build directories in the OSX repository %linux_git_root%/fds, on %osx_hostname%
plink %plink_options% %osx_logon% %scriptdir%/clean_repo_sourcebuild.sh
:skip_osx

:eof
pause
