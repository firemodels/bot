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

echo cleaning smokeview build directories
cd %smvrepo%\Source
git clean -dxf

cd %smvrepo%\Build
git clean -dxf

echo cleaning fds build directories
cd %fdsrepo%\Build
git clean -dxf

cd %fdsrepo%\Utilities
git clean -dxf

echo building smokeview libraries, utilities, program
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

echo building fds utilities, program
call :BUILDUTIL fds2ascii intel_win_64
call :BUILDUTIL test_mpi  impi_intel_win
call :BUILDFDS  impi_intel_win_64
echo build complete"

cd %CURDIR%

goto eof

:: -------------------------------------------------------------
 :BUILDFDS
:: -------------------------------------------------------------

echo
echo ********** building fds
echo
cd %fdsrepo%\Build\intel_win_64
call make_fds bot
exit /b /0

:: -------------------------------------------------------------
 :BUILDUTIL
:: -------------------------------------------------------------

set prog=%1
set builddir=%s
set script=make_%prog%

echo
echo ********** building %prog%
echo
cd %fdsrepo%\Utilities\%prog%\%build_dir%
call %script% bot
exit /b /0

:: -------------------------------------------------------------
 :BUILDLIB
:: -------------------------------------------------------------

echo
echo ********** building smokeview libraries
echo

cd %smvrepo%\Build\LIBS\intel_win_64
call make_LIBS_bot
exit /b /0

:: -------------------------------------------------------------
 :BUILDSMV
:: -------------------------------------------------------------

echo
echo ********** building smokeview
echo
cd %smvrepo%\Build\smokeview\intel_win_64
call make_smokeview -r bot
exit /b /0


:: -------------------------------------------------------------
 :BUILD
:: -------------------------------------------------------------

set prog=%1
set script=make_%prog%

echo
echo ********** building %prog%
echo
cd %smvrepo%\Build\%prog%\intel_win_64
call %script% bot
exit /b /0

:eof
