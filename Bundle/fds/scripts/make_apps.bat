@echo off

set CURDIR=%CD%

cd ..\..\..\..\smv\
set smvrepo=%CD%

cd ..\fds
set fdsrepo=%CD%

cd %smvrepo%\Build\LIBS
set libdir=%CD%

cd %fdsrepo%\Utilities
set utildir=%CD%

cd %smvrepo%\Source
echo ***cleaning %smvrepo%\Source
git clean -dxf  1>> Nul 2>&1

cd %smvrepo%\Build
echo ***cleaning %smvrepo%\Build
git clean -dxf  1>> Nul 2>&1

cd %fdsrepo%\Build
echo ***cleaning %fdsrepo%\Build
git clean -dxf  1>> Nul 2>&1

cd %fdsrepo%\Utilities
echo ***cleaning %fdsrepo%\Utilities
git clean -dxf  1>> Nul 2>&1

call :BUILDLIB              
call :BUILD     background
call :BUILD     dem2fds
call :BUILD     hashfile
call :BUILD     smokediff
call :BUILD     smokezip
call :BUILD     wind2fds
call :BUILD     set_path
call :BUILD     sh2bat
call :BUILD     get_time
call :BUILDSMV

call :BUILDUTIL fds2ascii intel_win_64 win_64
call :BUILDUTIL test_mpi  impi_intel_win
call :BUILDFDS

call :CHECK_BUILD     background
call :CHECK_BUILD     dem2fds
call :CHECK_BUILD     hashfile
call :CHECK_BUILD     smokediff
call :CHECK_BUILD     smokezip
call :CHECK_BUILD     wind2fds
call :CHECK_BUILD     set_path
call :CHECK_BUILD     sh2bat
call :CHECK_BUILD     get_time
call :CHECK_BUILDSMV

call :CHECK_BUILDUTIL fds2ascii intel_win_64 _win_64
call :CHECK_BUILDUTIL test_mpi  impi_intel_win
call :CHECK_BUILDFDS

echo.
echo ***build complete
echo.

cd %CURDIR%

goto eof

:: -------------------------------------------------------------
 :BUILDFDS
:: -------------------------------------------------------------

echo ***building fds
cd %fdsrepo%\Build\impi_intel_win_64
call make_fds bot 1>> Nul 2>&1
exit /b /0

:: -------------------------------------------------------------
 :CHECK_BUILDFDS
:: -------------------------------------------------------------

if NOT exist %fdsrepo%\Build\impi_intel_win_64\fds_impi_win_64.exe goto check_fds
exit /b /0
:check_fds
echo ***error: The program fds_impi_win_64.exe failed to build
exit /b /1

:: -------------------------------------------------------------
 :BUILDUTIL
:: -------------------------------------------------------------

set prog=%1
set builddir=%2

echo ***building %prog%
cd %fdsrepo%\Utilities\%prog%\%builddir%
call make_%prog% bot 1>> Nul 2>&1
exit /b /0

:: -------------------------------------------------------------
 :CHECK_BUILDUTIL
:: -------------------------------------------------------------

set prog=%1
set builddir=%2
set suffix=%3

if NOT exist %fdsrepo%\Utilities\%prog%\%builddir%\%prog%%suffix%.exe goto check_util
exit /b /0
:check_util
echo ***error: The program %prog%%suffix%.exe failed to build
exit /b /1

:: -------------------------------------------------------------
 :BUILDLIB
:: -------------------------------------------------------------

echo ***building smokeview libraries

cd %smvrepo%\Build\LIBS\intel_win_64
call make_LIBS_bot 1>> Nul 2>&1
exit /b /0

:: -------------------------------------------------------------
 :BUILDSMV
:: -------------------------------------------------------------

echo ***building smokeview
cd %smvrepo%\Build\smokeview\intel_win_64
call make_smokeview -release -bot 1>> Nul 2>&1
exit /b /0

:: -------------------------------------------------------------
 :CHECK_BUILDSMV
:: -------------------------------------------------------------

if NOT exist %smvrepo%\Build\smokeview\intel_win_64\smokeview_win_64.exe goto not_smokeview
exit /b /0
:not_smokeview
echo ***error: The program smokeview_win_64.exe failed to build
exit /b /1

:: -------------------------------------------------------------
 :BUILD
:: -------------------------------------------------------------

set prog=%1
set script=make_%prog%

echo ***building %prog%
cd %smvrepo%\Build\%prog%\intel_win_64
call %script% bot 1>> Nul 2>&1
exit /b /0

:: -------------------------------------------------------------
 :CHECK_BUILD
:: -------------------------------------------------------------

set prog=%1

if NOT exist %smvrepo%\Build\%prog%\intel_win_64\%prog%_win_64.exe goto notexist
exit /b /0
:notexist
echo ***error: The program %prog%_win_64.exe failed to build
exit /b /1

:eof
