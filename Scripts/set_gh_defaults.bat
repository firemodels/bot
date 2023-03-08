@echo off
setlocal

set repo_root=FireModels_fork
set CURDIR=%CD%
set user=%USERNAME%
::set user=firemodels
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

set scriptdir=%linux_svn_root%/bot/Scripts

cd %userprofile%\%repo_root%\%repo%
echo.
echo setting gh default: %user% on PC
gh repo set-default %user%/%repo% 
gh repo set-default --view 

echo.
echo setting gh default: %user% on %linux_logon%
plink %plink_options% %linux_logon% %scriptdir%/set_gh_defaults.sh %repo_root% %repo% %user%

::echo.
echo setting gh default: %user% on %osx_logon%
plink %plink_options% %osx_logon% %scriptdir%/set_gh_defaults.sh %repo_root% %repo% %user%
