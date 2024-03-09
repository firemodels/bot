@echo off
set platform=%1
set buildtype=%2
set inc=

:: batch file to build test or release smokeview on Windows, Linux or OSX platforms

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
echo.
echo  Building %buildtype% Smokezip for %platform%
Title Building %buildtype% Smokezip for %platform%

%git_drive%

set wintype=
set type=
set wininc=
set inc=

if "%platform%" == "Windows" (
  cd %git_root%\smv\Build\smokezip\intel_win_64
  call make_smokezip
  goto eof
)

:: ----------- linux -----------------

if "%platform%" == "Linux" (
  plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command.sh smv/Build/smokezip/intel_linux_64 make_smokezip.sh
  goto eof
)

:: ----------- osx -----------------

if "%platform%" == "OSX" (
  plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command.sh smv/Build/smokezip/intel_osx_64 make_smokezip.sh
  goto eof
)

:eof
echo.
echo compilation complete
pause
