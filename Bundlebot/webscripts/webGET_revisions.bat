@echo off

:: batch file to output git repo revision string

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

set bundledir=%userprofile%\.bundle

if EXIST %bundledir%\smv_revision.txt  goto else1
echo ***error: smv test revision does not exist
goto endif1
:else1
set /p revision=<%bundledir%\smv_revision.txt
echo smv test revision: %revision%
:endif1

if EXIST %bundledir%\fds_revision.txt  goto else2
echo ***error: fds test revision does not exist
goto endif2
:else2
set /p revision=<%bundledir%\fds_revision.txt
echo fds test revision: %revision%
:endif2

echo smv release revision: %smv_version%
echo fds release revision: %fds_version%

pause
