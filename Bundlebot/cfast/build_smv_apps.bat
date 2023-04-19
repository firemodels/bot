@echo off
setlocal
set smvrepo=%1
set CURDIR=%CD%

:: batch file to build smokeview utility programs on Windows, Linux or OSX platforms

call %smvrepo%\Utilities\Scripts\setup_intel_compilers.bat

echo ***Building Libraries
cd %smvrepo%\..\bot\Bundlebot\cfast
call build_smv_libs > Nul 2>&1

set progs=background get_time set_path sh2bat smokediff smokezip wind2fds    
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
