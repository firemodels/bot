@echo off
set revision_arg=%1
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

set CURDIR=%CD%
call %envfile%

%svn_drive%
set scriptdir=%svn_root%\bot\Bundlebot\smv\scripts

call %scriptdir%\make_bundle test %revision_arg%
