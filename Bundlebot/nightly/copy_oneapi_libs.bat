@echo off
set locscriptdir=%~dp0
set TODIR=%1

if NOT exist %TODIR%     mkdir %TODIR%
if NOT exist %TODIR%\mpi mkdir %TODIR%\mpi

:: setup compiler environment
call %locscriptdir%\..\..\..\fds\build\Scripts\setup_intel_compilers.bat  > Nul 2>&1

where impi.dll | head -1 > %locscriptdir%\output\impi.txt
set /p IMPI=<output\impi.txt
for %%I in ("%IMPI%") do set "IMPIDIR=%%~dpI"
echo.
echo ***copying mpi exe files
echo.
copy "%IMPIDIR%"\*.exe %TODIR%\mpi

where libfabric.dll | head -1 > %locscriptdir%\output\libfabric.txt
set /p LIBFABRIC=<output\libfabric.txt
for %%I in ("%LIBFABRIC%") do set "LIBFABRICDIR=%%~dpI"
echo.
echo ***copying libfabric.dll
echo.
echo copy "%LIBFABRICDIR%"\libfabric.dll %TODIR%\mpi
copy "%LIBFABRICDIR%"\libfabric.dll %TODIR%\mpi

echo.
echo ***copying mpi dll files
echo.
copy "%IMPIDIR%"\*.dll %TODIR%\mpi

echo.
echo  ***copying mpi shared libraries
echo.
where libiomp5md.dll | head -1 > %locscriptdir%\output\libiomp5md.txt
set /p LIBIOMP=<output\libiomp5md.txt
echo %LIBIOMP%
copy "%LIBIOMP%" %TODIR%