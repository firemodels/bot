@echo off
set "I_MPI_ROOT=%~dp0mpi"
set "PATH=%I_MPI_ROOT%;%PATH%"
set IN_CMDFDS=1
set MPIEXEC_PORT_RANGE=
set MPICH_PORT_RANGE=

for %%I in ("%~dp0..\..\SMV6\smokeview.exe") do set "SMOKEVIEW_EXE=%%~fI"
doskey fds="%~dp0fds.exe" $*
doskey smokeview="%SMOKEVIEW_EXE%" $*
doskey fds_local="%~dp0fds_local.bat" $*
doskey helpfds="%~dp0helpfds.bat" $*

title FDS
echo.
echo type helpfds for help on running fds

