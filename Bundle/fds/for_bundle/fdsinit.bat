@echo off
SET I_MPI_ROOT=%~dp0\mpi
SET PATH=%I_MPI_ROOT%;%PATH%
doskey fdss=mpiexec -localonly -np  1 fds.exe $1 
doskey fdsm=mpiexec -localonly -np $1 fds.exe $2 
title FDS
echo.
echo type helpfds for help on running fds

