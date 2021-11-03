@echo off
set INTELDIR=INTELoneapiu4

if x%INTELDIR% == x echo error ***error: INTELDIR not defined, edit script to define
if x%INTELDIR% == x exit /b

:: define and make directories containing run time files copied to the bundle
set TODIRBASE=%userprofile%\.bundle\BUNDLE\WINDOWS
set DIST_INTELDIR=%TODIRBASE%\%INTELDIR%
set DIST_INTELMPIDIR=%TODIRBASE%\%INTELDIR%\mpi

set CURDIR=%CD%
cd %TODIRBASE%
if exist %INTELDIR% rmdir /s /q %INTELDIR%
mkdir %INTELDIR%
mkdir %INTELDIR%\mpi

::*** files from bin directory

set "FROMDIR=%I_MPI_ONEAPI_ROOT%\bin"
set TODIR=%DIST_INTELMPIDIR%

echo %INTELDIR% > %DIST_INTELDIR%\version
echo.
echo ***copying files from %FROMDIR%
call :copyfile hydra_bstrap_proxy.exe
call :copyfile hydra_pmi_proxy.exe
call :copyfile hydra_service.exe
call :copyfile IMB-MPI1.exe
call :copyfile IMB-NBC.exe
call :copyfile IMB-RMA.exe
call :copyfile libmpi_ilp64.dll
call :copyfile mpiexec.exe

::*** files from release directory

set "FROMDIR=%I_MPI_ONEAPI_ROOT%\bin\release"
set TODIR=%DIST_INTELMPIDIR%

echo.
echo ***copying file from %FROMDIR%
call :copyfile impi.dll

::*** files from libfabric\bin directory

set "FROMDIR=%I_MPI_ONEAPI_ROOT%\libfabric\bin"
set TODIR=%DIST_INTELMPIDIR%

echo.
echo ***copying file from %FROMDIR%
call :copyfile libfabric.dll

set "FROMDIR=%ONEAPI_ROOT%\compiler\latest\windows\redist\intel64_win\compiler"
set TODIR=%DIST_INTELDIR%

echo.
echo ***copying file from %FROMDIR%
call :copyfile libiomp5md.dll

echo.
echo ***copy complete
goto eof

::---------------------------------------------
  :copyfile
::---------------------------------------------

set FROMFILE=%1

if NOT exist "%FROMDIR%\%FROMFILE%" echo "***error: %FROMFILE% was not found in %FROMDIR%"
if NOT exist "%FROMDIR%\%FROMFILE%" exit /b

copy "%FROMDIR%\%FROMFILE%" %TODIR%\%FROMFILE% > Nul 2> Nul
if exist     %TODIR%\%FROMFILE% echo    %FROMFILE% copied
if NOT exist %TODIR%\%FROMFILE% echo ***error: %FROMFILE% failed to copy
exit /b

:eof
cd %CURDIR%