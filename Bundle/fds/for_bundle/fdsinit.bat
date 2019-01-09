@echo off
SET I_MPI_ROOT=%~dp0\mpi
SET PATH=%I_MPI_ROOT%;%PATH%
doskey fdss=mpiexec -localonly -np  1 fds.exe $1 
doskey fdsm=mpiexec -localonly -np $1 fds.exe $2 
title FDS
echo OMP_NUM_THREADS=%OMP_NUM_THREADS%
echo fdss casename.fds
echo fdsm xx casename.fds
echo mpiexec -np xx fds casename.fds
echo.

