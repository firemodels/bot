@echo off

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

set scriptdir=%linux_git_root%/bot/Scripts/

echo.
echo ---------------------------*** smv ***--------------------------------
cd %git_root%\smv
echo Windows
git checkout devel

echo.
echo Linux
plink %plink_options% %linux_logon% %scriptdir%/setbranch_devel.sh  %linux_git_root%/smv

echo.
echo OSX
plink %plink_options% %osx_logon% %scriptdir%/setbranch_devel.sh  %linux_git_root%/smv


echo.
pause
