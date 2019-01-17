@echo off
SET I_MPI_ROOT=%~dp0\mpi
SET PATH=%I_MPI_ROOT%;%PATH%
doskey fds_local=mpiexec -localonly $1 $2 fds.exe $3 
title FDS
echo.
echo type helpfds for help on running fds

