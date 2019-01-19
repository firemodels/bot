@echo off
echo.
echo Current number of OpenMP threads per MPI process:
echo OMP_NUM_THREADS=%OMP_NUM_THREADS%
echo.
echo For jobs using this computer only:
echo fds_local -p xx casename.fds
echo.
echo for more options type: fds_local -h
echo.
echo For jobs using multiple computers:
echo mpiexec -n xx -hostfile hostfile.txt -wdir WDIR -env OMP_NUM_THREADS yy fds casename.fds
echo.
echo    xx -- number of MPI processes requested 
echo    yy -- number of OpenMP threads requested per MPI process
echo    hostfile.txt -- list of available computers
echo    WDIR -- Network address of the working directory
echo.

