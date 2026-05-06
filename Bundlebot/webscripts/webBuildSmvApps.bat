@echo off
setlocal\

set CURDIR=%CD%
cd %CURDIR%\..\..\..\smv\Build\smokeview\intel_win
start "build smokeview" cmd /c "call make_smokeview"

cd %CURDIR%\..\..\..\smv\Build\fds2fed\intel_win
start "build smokeview" cmd /c "call make_fds2fed"
