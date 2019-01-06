@echo off
title FDS
set mpibindir="%~dp0\mpi\intel64\bin"
call %mpibindir%\mpivars
doskey fds=mpiexec -localonly fdsmpi.exe $* 

