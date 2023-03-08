@echo off
setlocal

set repo_root=FireModels_fork
set CURDIR=%CD%
set user=%USER%
set user=firemodels

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

set scriptdir=%svn_root%\bot\Scripts

cd %userprofile%\%repo_root%\test_bundles
gh repo set-default %user%/test_bundles 

plink %plink_options% %linux_logon% %scriptdir%/set_gh_defaults.sh %repo_root%/test_bundles %user%/test_bundles

plink %plink_options% %osx_logon%   %scriptdir%/set_gh_defaults.sh %repo_root%/test_bundles %user%/test_bundles