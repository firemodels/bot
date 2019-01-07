@echo off
set mpibindir="%~dp0\mpi"
call %mpibindir%\mpivars
doskey fds=mpiexec -localonly -np 1 fdsmpi.exe $* 
title FDS

