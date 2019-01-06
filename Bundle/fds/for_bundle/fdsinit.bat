@echo off
set mpibindir="%~dp0\mpi\intel64\bin"
call %mpibindir%\mpivars
doskey fds=mpiexec -localonly -np 1 fdsmpi.exe $* 
title FDS

