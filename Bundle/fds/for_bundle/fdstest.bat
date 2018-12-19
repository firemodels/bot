@echo off
set curdir=%CD%
set mpibindir="%~dp0\mpi\intel64\bin"
call "%~dp0\fdsinit"
"%~dp0\fds.exe" %*


