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
if not exist %bundledir% (
  mkdir %bundledir%
)

%svn_drive%
cd %svn_root%\smv
git describe --long --dirty > %bundledir%\smv_revision.txt
set /p revision=<%bundledir%\smv_revision.txt
echo smv revision: %revision%

cd %svn_root%\fds
git describe --long --dirty > %bundledir%\fds_revision.txt
set /p revision=<%bundledir%\fds_revision.txt
echo fds revision: %revision%
pause
