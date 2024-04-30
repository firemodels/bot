@echo off
set revision_arg=%1
set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% goto endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
goto eof

:endif_envexist

set CURDIR=%CD%
call %envfile%

%git_drive%
set scriptdir=%~dp0

call %scriptdir%\make_bundle test %revision_arg%

:eof
