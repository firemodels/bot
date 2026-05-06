@echo off
setlocal\

cd ..\..\..\fds\Build\impi_intel_win
start "build fds" cmd /c "call make_fds"
