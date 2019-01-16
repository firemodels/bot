@echo off
SET I_MPI_ROOT=%~dp0\mpi
SET PATH=%I_MPI_ROOT%;%PATH%
doskey fds_local=mpiexec -localonly -n $1 fds.exe $2 
title FDS
echo.
echo type helpfds for help on running fds

