@echo off
echo.
echo fdss casename.fds   - shortcut for mpiexec -localonly -np 1 fds casename.fds
echo fdsm n casename.fds - shortcut for mpiexec -localonly -np n fds casename.fds
echo.
echo Number of OpenMP threads
echo OMP_NUM_THREADS=%OMP_NUM_THREADS%
echo.
echo When using fdsm or mpiexec with n greater than one, it is 
echo recommended to set the number of OpenMP threads to 1 using 
echo set OMP_NUM_THREADS=1
echo.

