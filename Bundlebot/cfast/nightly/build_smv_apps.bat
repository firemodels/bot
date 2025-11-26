@echo off
setlocal
set CURDIR=%CD%

:: batch file to build smokeview utility programs on Windows, Linux or OSX platforms

cd ..\..\..\..\smv
set smvrepo=%CD%

call %smvrepo%\Utilities\Scripts\setup_intel_compilers.bat

echo ***Building Libraries
cd %CURDIR%
call build_smv_libs > Nul 2>&1

set progs=background get_time set_path sh2bat smokediff smokezip wind2fds    
for %%x in ( %progs% ) do (
  cd %smvrepo%\Build\%%x\intel_win
  echo ***Building %%x
  call make_%%x bot > Nul 2>&1
  if NOT exist %%x_win.exe echo ***error: %%x_win.exe does not exist::
)
cd %smvrepo%\Build\smokeview\intel_win 
call make_smokeview -test -bot > Nul 2>&1
if NOT exist smokeview_win_test.exe echo ***error: smokeview_win_test.exe does not exist

cd %CURDIR%
