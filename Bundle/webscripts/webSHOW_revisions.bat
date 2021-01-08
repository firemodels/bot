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

echo ---------------------------*** fds ***--------------------------------
%svn_drive%
cd %svn_root%\fds
call :output_rev

set scriptdir=%linux_svn_root%/bot/Scripts/
set linux_fdsdir=%linux_svn_root%

echo | set /p=Linux:   
plink %plink_options% %linux_logon% %scriptdir%/showrevision.sh  %linux_svn_root%/fds

echo | set /p=OSX:     
plink %plink_options% %osx_logon% %scriptdir%/showrevision.sh  %linux_svn_root%/fds

echo ---------------------------*** smv ***--------------------------------
cd %svn_root%\smv
call :output_rev

echo | set /p=Linux:   
plink %plink_options% %linux_logon% %scriptdir%/showrevision.sh  %linux_svn_root%/smv

echo | set /p=OSX:     
plink %plink_options% %osx_logon% %scriptdir%/showrevision.sh  %linux_svn_root%/smv

echo ---------------------------*** bot ***--------------------------------
cd %svn_root%\bot
call :output_rev

echo | set /p=Linux:   
plink %plink_options% %linux_logon% %scriptdir%/showrevision.sh  %linux_svn_root%/bot

echo | set /p=OSX:     
plink %plink_options% %osx_logon% %scriptdir%/showrevision.sh  %linux_svn_root%/bot

echo ---------------------------*** web ***--------------------------------
cd %svn_root%\webpages
call :output_rev

echo | set /p=Linux:   
plink %plink_options% %linux_logon% %scriptdir%/showrevision.sh  %linux_svn_root%/webpages

echo | set /p=OSX:     
plink %plink_options% %osx_logon% %scriptdir%/showrevision.sh  %linux_svn_root%/webpages
pause
goto eof

::---------------------------------------------------------
:output_rev
::---------------------------------------------------------
echo | set /p=Windows: 
git describe --dirty > tmp1
git branch --show-current > tmp2
set /p revision=<tmp1
set /p branch=<tmp2
echo %revision%/%branch%
erase tmp1 tmp2
exit /b

:eof
