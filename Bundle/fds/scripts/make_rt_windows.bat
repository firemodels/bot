@echo off
set INTELDIR=INTELoneapiu3

set TODIRBASE=%userprofile%\.bundle\BUNDLE\WINDOWS
set TODIR=%TODIRBASE%\%INTELDIR%

set CURDIR=%CD%
cd %TODIRBASE%
if exist %INTELDIR% rmdir /s /q %INTELDIR%
mkdir %INTELDIR%

set "FROMDIR=%I_MPI_ONEAPI_ROOT%\bin"

echo %INTELDIR% > %TODIR%\version
echo.
echo ***copying files from %FROMDIR%
echo.
call :copyfile hydra_bstrap_proxy.exe
call :copyfile hydra_pmi_proxy.exe
call :copyfile hydra_service.exe
call :copyfile IMB-MPI1.exe
call :copyfile IMB-NBC.exe
call :copyfile IMB-RMA.exe
call :copyfile libmpi_ilp64.dll
call :copyfile mpiexec.exe

set "FROMDIR=%I_MPI_ONEAPI_ROOT%\bin\release"

echo.
echo ***copying files from %FROMDIR%
echo.
call :copyfile impi.dll

set "FROMDIR=%I_MPI_ONEAPI_ROOT%\libfabric\bin"

echo.
echo ***copying files from %FROMDIR%
echo.
call :copyfile libfabric.dll

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
if exist "%TODIR%\%FROMFILE%" echo    %FROMFILE% copied
if NOT exist %TODIR%\%FROMFILE% echo ***error: %FROMFILE% failed to copy
exit /b

:eof
cd %CURDIR%