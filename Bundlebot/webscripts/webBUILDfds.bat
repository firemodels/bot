@echo off
set platform=%1

:: batch file to build FDS on Windows, Linux or OSX platforms

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
echo  Building release FDS for %platform%
Title Building release FDS for %platform%

%git_drive%

if "%platform%" == "windows" (
  cd %git_root%\fds\Build\impi_intel_win_64
  erase *.obj *.mod *.exe
  call make_fds
  goto eof
)
set INTEL=
if "%linux_mpi_version%" == "INTEL" (
  set INTEL=i
)
if "%platform%" == "linux" (
  plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command.sh fds/Build/Scripts clean.sh %INTEL%mpi_intel_linux_64
  plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command.sh fds/Build/%INTEL%mpi_intel_linux_64 make_fds.sh
  pause
  goto eof
)
if "%platform%" == "osx" (
  plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command.sh fds/Build/Scripts clean.sh mpi_intel_osx_64
  plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command.sh fds/Build/mpi_intel_osx_64 make_fds.sh
  pause
  goto eof
)

:eof
