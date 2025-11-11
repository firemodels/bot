@echo off
setlocal EnableDelayedExpansion

:: batch file to install the FDS-SMV bundle on Windows, Linux or OSX systems

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
echo.

echo cleaning smokeview build directories

echo *** windows
cd %git_root%\smv\Build\smokeview\intel_win
git clean -dxf

echo.
echo *** linux
plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/intel_linux
plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/gnu_linux 


echo.
echo *** osx
plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/intel_osx
plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/intel_osx_q 
plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/gnu_osx 


echo.
pause
