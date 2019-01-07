@echo off
SET I_MPI_ROOT=%~dp0\mpi
SET PATH=%I_MPI_ROOT%;%PATH%
doskey fds=mpiexec -localonly -np 1 fdsmpi.exe $* 
title FDS
::echo OMP_NUM_THREADS=%OMP_NUM_THREADS% (set to 1 if using MPI)

