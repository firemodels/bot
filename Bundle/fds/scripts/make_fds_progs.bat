@echo off
set CURDIR=%CD%
cd ..\..\..\..\fds\Build\impi_intel_win_64

git clean -dxf
echo.
echo ********** build FDS
echo.
call make_fds bot

echo.
echo ********** build fds2ascii
echo.
cd ..\..\Utilities\fds2ascii\intel_win_64
call make_fds2ascii bot

echo.
echo ********** build test_mpi
echo.
cd ..\..\..\Utilities\test_mpi\impi_intel_win
call make_test_mpi bot

cd %CURDIR%
