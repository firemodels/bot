@echo off
set platform=%1

set CURDIR=%CD%

:: batch file to build smokeview utility programs on Windows, Linux or OSX platforms

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
echo  Building smokeview utilities for 64 bit %platform%
Title Building smokeview utilities for 64 bit %platform%

%git_drive%

set EXIT_SCRIPT=1

set progs=background flush hashfile pnginfo smokediff fds2fed smokezip wind2fds
set smvprogs=get_time set_path sh2bat timep

if NOT "%platform%" == "Windows" goto endif1
  for %%x in ( %progs% ) do (
    cd %git_root%\smv\Build\%%x\intel_win_64
    start "building windows %%x" make_%%x
  ) 
  for %%x in ( %smvprogs% ) do (
    cd %git_root%\smv\Build\%%x\intel_win_64
    start "building windows %%x" make_%%x
  ) 
  ) 
::  call :not_built
  goto eof
:endif1

if NOT "%platform%" == "Linux" goto endif2
  for %%x in ( %progs% ) do (
    start "building linux %%x" plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command.sh smv/Build/%%x/intel_linux_64 make_%%x.sh
  )
  start "building linux %%x" plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command.sh fds/Utilities/fds2ascii/intel_linux make_fds2ascii.sh
  pause
  goto eof
:endif2

if NOT "%platform%" == "OSX" goto endif3
  for %%x in ( %progs% ) do (
    start "building osx %%x" plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command.sh smv/Build/%%x/gnu_osx_64 make_%%x.sh
  )
  start "building osx fds2ascii" plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command.sh fds/Utilities/fds2ascii/gnu_osx make_fds2ascii.sh
  pause
  goto eof
:endif3
goto eof

:eof
echo.
cd %CURDIR%
