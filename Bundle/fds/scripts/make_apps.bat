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
call :BUILDSMV  smokeview

call :BUILDUTIL fds2ascii intel_win_64
call :BUILDUTIL test_mpi  impi_intel_win
call :BUILDFDS
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
 :BUILDUTIL
:: -------------------------------------------------------------

set prog=%1
set builddir=%s
set script=make_%prog%

echo ***building %prog%
cd %fdsrepo%\Utilities\%prog%\%build_dir%
call %script% bot 1>> Nul 2>&1
exit /b /0

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
call make_smokeview -r bot 1>> Nul 2>&1
exit /b /0

:: -------------------------------------------------------------
 :BUILD
:: -------------------------------------------------------------

set prog=%1
set script=make_%prog%

echo ***building %prog%
cd %smvrepo%\Build\%prog%\intel_win_64
call %script% bot 1>> Nul 2>&1
exit /b /0

:eof
