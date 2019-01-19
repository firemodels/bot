@echo off

set nmpi=1
set n_openmp=1
set show_only=0
set stopscript=0

call :getopts %*
if "%stopscript%" == "1" exit /b

set ECHO=
if "%show_only%" == "1" set ECHO=echo

if "%show_only%" == "1" goto skip_casename_test
  if EXIST %casename% goto skip_casaename_test
    echo ***error: The file %casename% does not exist
    exit /b
:skip_casename_test
 
%ECHO% mpiexec -localonly -n %nmpi% -env OMP_NUM_THREADS %n_openmp% fds %casename%

goto eof

:-------------------------------------------------------------------------
:----------------------subroutines----------------------------------------
:-------------------------------------------------------------------------

:-------------------------------------------------------------------------
:getopts
:-------------------------------------------------------------------------
 if (%1)==() exit /b

 set casename=%1
 set case1=%casename:~0,1%
 if NOT "%case1%" == "-" exit /b

 set valid=0
 set arg=%1
 if /I "%1" EQU "-n" (
   set valid=1
   set nmpi=%2
   shift
 )
 if /I "%1" EQU "-v" (
   set valid=1
   set show_only=1
 )
 if /I "%1" EQU "-help" (
   set valid=1
   set stopscript=1
   call :usage
   exit /b
 )
 if /I "%1" EQU "-m" (
   set valid=1
   set n_openmp=%2
   shift
 )
 shift
 if %valid% == 0 (
   echo.
   echo ***Error: the input argument %arg% is invalid
   echo.
   echo Usage:
   call :usage
   set stopscript=1
   exit /b
 )
if not (%1)==() goto getopts
exit /b

:-------------------------------------------------------------------------
:usage  
:-------------------------------------------------------------------------
echo fds_local  [options] casename.fds
echo. 
echo -help           - display this message
echo -n n - specify number of mpi processes
echo       (default: 1) 
echo -m m - specify number of OpenMP threads per mpi process
echo       (default: 1) 
exit /b

:eof
exit /b

