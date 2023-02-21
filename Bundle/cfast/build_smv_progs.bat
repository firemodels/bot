@echo off
setlocal
set smvrepo=%1
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

%svn_drive%

cd %smvrepo%\Build\LIBS\intel_win_64
echo ***Building Libraries
call make_LIBS_bot > Nul 2>&1

set progs=background get_time set_path sh2bat smokediff smokezip wind2fds    
call %smvrepo%\Utilities\Scripts\setup_intel_compilers.bat
for %%x in ( %progs% ) do (
  cd %smvrepo%\Build\%%x\intel_win_64
  echo ***Building %%x
  call make_%%x bot > Nul 2>&1
  if NOT exist %%x_win_64.exe echo ***error: %%x_win_64.exe does not exist::
)
cd %smvrepo%\Build\smokeview\intel_win_64 
call make_smokeview -test -bot > Nul 2>&1
if NOT exist smokeview_win_test_64.exe echo ***error: smokeview_win_test_64.exe does not exist

cd %CURDIR%
